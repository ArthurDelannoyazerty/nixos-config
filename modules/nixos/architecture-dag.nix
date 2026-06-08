{ pkgs, ... }:

let
  nixosDir = "/home/arthur/nixos-config";

  generateDagScript = pkgs.writeScript "generate-dag.py" ''
    #!${pkgs.python3}/bin/python
    import sys
    import re
    from pathlib import Path
    from collections import defaultdict

    def generate_dag(repo_path):
        base_dir = Path(repo_path).resolve()
        root = base_dir / "flake.nix"
        
        if not root.exists():
            print(f"Error: flake.nix not found in {repo_path}")
            return
            
        queue = [root]
        visited = set()
        edges_raw = set()
        
        while queue:
            current = queue.pop(0)
            if current in visited: continue
            visited.add(current)
            
            try:
                content = current.read_text(encoding="utf-8")
            except: 
                continue
                
            content = re.sub(r"/\*.*?\*/", "", content, flags=re.DOTALL)
            content = re.sub(r"#.*", "", content)
            matches = re.findall(r"(?<![\w\-])(\.\.?/[\w\.\-\/]+)", content)
            
            for m in matches:
                target = (current.parent / m).resolve()
                final_target = None
                
                if target.is_dir() and (target / "default.nix").is_file():
                    final_target = target / "default.nix"
                elif target.is_file() and target.suffix == ".nix":
                    final_target = target
                    
                if final_target and str(final_target).startswith(str(base_dir)):
                    try:
                        p_rel = current.relative_to(base_dir).as_posix()
                        c_rel = final_target.relative_to(base_dir).as_posix()
                        edges_raw.add((p_rel, c_rel))
                    except ValueError:
                        pass
                        
                    if final_target not in visited:
                        queue.append(final_target)

        nodes = set()
        for p, c in edges_raw:
            nodes.add(p)
            nodes.add(c)
            
        if not nodes: nodes.add("flake.nix")
            
        node_ids = {n: f"N{i}" for i, n in enumerate(sorted(nodes))}
        
        by_dir = defaultdict(list)
        for n in sorted(nodes):
            folder = str(Path(n).parent)
            if folder == ".": folder = "/"
            by_dir[folder].append(n)

        def sanitize_id(text):
            return re.sub(r'[^a-zA-Z0-9]', '_', text)

        # Build Graphviz DOT file
        dot_path = base_dir / "dag.dot"
        with open(dot_path, "w", encoding="utf-8") as f:
            f.write("digraph NixOS {\n")
            
            # --- STYLING ---
            f.write('  rankdir=LR;\n') # Left to Right
            f.write('  compound=true;\n') # Allow edges to subgraphs
            f.write('  splines=polyline;\n') # Orthogonal, clean lines instead of messy curves
            f.write('  nodesep=0.3;\n')
            f.write('  ranksep=1.2;\n')
            
            # Global node styling (Modern, rounded boxes)
            f.write('  node [fontname="Helvetica,Arial,sans-serif", fontsize=10, shape=box, style="rounded,filled", fillcolor="#f8f9fa", color="#ced4da", fontcolor="#212529"];\n')
            # Global edge styling
            f.write('  edge [color="#6c757d", penwidth=1.0, arrowsize=0.7];\n\n')

            # --- NODES & FOLDERS ---
            for folder, files in by_dir.items():
                if folder == "/":
                    for file in files:
                        name = Path(file).name
                        f.write(f'  {node_ids[file]} [label="📄 {name}"];\n')
                else:
                    cluster_id = sanitize_id(folder)
                    f.write(f'  subgraph cluster_{cluster_id} {{\n')
                    f.write(f'    label="📁 {folder}";\n')
                    # Folder styling
                    f.write('    style="rounded,filled";\n')
                    f.write('    fillcolor="#e9ecef";\n')
                    f.write('    color="#adb5bd";\n')
                    f.write('    fontname="Helvetica-Bold";\n')
                    f.write('    fontsize=12;\n')
                    f.write('    fontcolor="#495057";\n')
                    f.write('    margin=15;\n')
                    
                    for file in files:
                        name = Path(file).name
                        f.write(f'    {node_ids[file]} [label="📄 {name}"];\n')
                    f.write("  }\n\n")
            
            # --- EDGES ---
            for p, c in sorted(edges_raw):
                f.write(f'  {node_ids[p]} -> {node_ids[c]};\n')
            
            f.write("}\n")

        # Create the Markdown wrapper
        md_path = base_dir / "ARCHITECTURE.md"
        with open(md_path, "w", encoding="utf-8") as f:
            f.write("# ❄️ NixOS Inter-File Dependency Graph\n\n")
            f.write("> Auto-generated during `nixos-rebuild`.\n\n")
            f.write("![Architecture Diagram](./ARCHITECTURE.svg)\n")

    if __name__ == "__main__":
        if len(sys.argv) > 1:
            generate_dag(sys.argv[1])
  '';
in {
  system.activationScripts.generateArchitectureDag = {
    text = ''
      if [ -d "${nixosDir}" ]; then
        # 1. Generate the dag.dot and ARCHITECTURE.md files
        ${generateDagScript} "${nixosDir}"
        
        # 2. Compile the .dot file into a beautiful SVG
        ${pkgs.graphviz}/bin/dot -Tsvg "${nixosDir}/dag.dot" -o "${nixosDir}/ARCHITECTURE.svg"
        
        # 3. Clean up the temporary dot file
        rm -f "${nixosDir}/dag.dot"
        
        # 4. Fix permissions so you can commit them
        chown -R arthur:users "${nixosDir}/ARCHITECTURE.md" "${nixosDir}/ARCHITECTURE.svg" || true
      fi
    '';
  };
}