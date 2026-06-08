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
        edges = set()
        
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
                        edges.add((p_rel, c_rel))
                    except ValueError:
                        pass
                        
                    if final_target not in visited:
                        queue.append(final_target)

        # Build Mermaid Markdown
        md_path = base_dir / "ARCHITECTURE.md"
        with open(md_path, "w", encoding="utf-8") as f:
            f.write("# ❄️ NixOS Inter-File Dependency Graph\n\n")
            f.write("```mermaid\n")
            # Enable the advanced layout engine for better line routing
            f.write("%%{init: {\"flowchart\": {\"defaultRenderer\": \"elk\"}} }%%\n")
            f.write("graph LR\n\n")
            
            nodes = set()
            for p, c in edges:
                nodes.add(p)
                nodes.add(c)
                
            if not nodes:
                nodes.add("flake.nix")
                
            # Assign IDs
            node_ids = {n: f"N{i}" for i, n in enumerate(sorted(nodes))}
            
            # Group nodes by their parent directory to use Subgraphs
            by_dir = defaultdict(list)
            for n in sorted(nodes):
                path = Path(n)
                folder = str(path.parent)
                if folder == ".":
                    folder = "/"
                by_dir[folder].append(n)
                
            # Output nodes inside subgraphs
            for folder, files in by_dir.items():
                if folder == "/":
                    for file in files:
                        name = Path(file).name
                        f.write(f"  {node_ids[file]}[\"📄 {name}\"]\n")
                else:
                    # Create a visual bounding box for the folder
                    f.write(f"  subgraph \"📂 {folder}\"\n")
                    f.write("    direction LR\n")
                    for file in files:
                        name = Path(file).name
                        # Only display the filename in the box to keep it small
                        f.write(f"    {node_ids[file]}[\"📄 {name}\"]\n")
                    f.write("  end\n\n")
            
            # Output the linking arrows
            for p, c in sorted(edges):
                f.write(f"  {node_ids[p]} --> {node_ids[c]}\n")
            
            f.write("```\n")

    if __name__ == "__main__":
        if len(sys.argv) > 1:
            generate_dag(sys.argv[1])
  '';
in {
  system.activationScripts.generateArchitectureDag = {
    text = ''
      if [ -d "${nixosDir}" ]; then
        ${generateDagScript} "${nixosDir}"
        chown -R arthur:users "${nixosDir}/ARCHITECTURE.md" || true
      fi
    '';
  };
}