{ pkgs, dotfilesDir ? "/home/arthur/dotfiles", ... }:

let
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
        
        # Mapping: parent_file -> set(imported_files)
        deps = defaultdict(set)
        
        while queue:
            current = queue.pop(0)
            if current in visited: continue
            visited.add(current)
            
            try:
                content = current.read_text(encoding='utf-8')
            except: 
                continue
                
            # Remove Nix comments to avoid parsing commented-out code
            content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
            content = re.sub(r'#.*', '', content)
            
            # Find literal relative Nix paths (e.g., ./foo.nix, ../../bar)
            matches = re.findall(r'(?<![\w\-])(\.\.?/[\w\.\-\/]+)', content)
            
            for m in matches:
                target = (current.parent / m).resolve()
                final_target = None
                
                # Emulate Nix's path resolution logic
                if target.is_file() and target.suffix == '.nix':
                    final_target = target
                elif target.is_dir() and (target / 'default.nix').is_file():
                    final_target = target / 'default.nix'
                    
                # Only track imports that exist inside your flake
                if final_target and str(final_target).startswith(str(base_dir)):
                    deps[current].add(final_target)
                    if final_target not in visited:
                        queue.append(final_target)

        # Build Mermaid Markdown
        md_path = base_dir / "ARCHITECTURE.md"
        with open(md_path, "w", encoding="utf-8") as f:
            f.write("# ❄️ NixOS Inter-File Dependency Graph\n\n")
            f.write("> **Note:** Auto-generated based on actual logical `imports` and paths.\n\n")
            f.write("```mermaid\n")
            f.write("graph LR\n")
            
            node_ids = {}
            id_counter = 0
            def get_id(k):
                nonlocal id_counter
                if k not in node_ids:
                    node_ids[k] = f"N{id_counter}"
                    id_counter += 1
                return node_ids[k]

            global_folders = defaultdict(set)
            edges = []
            
            # Analyze all parent files and map the targets to their respective folders
            for parent, targets in deps.items():
                try: parent_rel = parent.relative_to(base_dir)
                except ValueError: parent_rel = parent.name
                
                parent_id = get_id(str(parent_rel))
                f.write(f'  {parent_id}["📄 {parent_rel}"]\n')
                
                parent_calls_folders = set()
                for t in targets:
                    try: t_rel = t.relative_to(base_dir)
                    except ValueError: t_rel = t.name
                    folder = str(t_rel.parent)
                    
                    global_folders[folder].add(t_rel.name)
                    parent_calls_folders.add(folder)
                    
                # Create edges from the Parent File to the Target Group Folder
                for folder in parent_calls_folders:
                    folder_id = get_id(f"DIR_{folder}")
                    edges.append((parent_id, folder_id))
                    
            # Print the grouped nodes ("Merge similar nodes")
            for folder, files in global_folders.items():
                folder_id = get_id(f"DIR_{folder}")
                files_sorted = sorted(list(files))
                
                if len(files_sorted) == 1 and files_sorted[0] == "default.nix":
                    label = f"📁 {folder}"
                else:
                    files_str = "<br>".join([f"📄 {fn}" for fn in files_sorted])
                    label = f"📁 {folder}<br>──────────<br>{files_str}"
                
                f.write(f'  {folder_id}["{label}"]\n')
                
            # Output the linking arrows
            for pid, fid in edges:
                f.write(f'  {pid} --> {fid}\n')
            
            f.write("```\n")

    if __name__ == "__main__":
        if len(sys.argv) > 1:
            generate_dag(sys.argv[1])
  '';
in {
  system.activationScripts.generateArchitectureDag = {
    text = ''
      if [ -d "${dotfilesDir}" ]; then
        ${generateDagScript} "${dotfilesDir}"
        chown -R arthur:users "${dotfilesDir}/ARCHITECTURE.md" || true
      fi
    '';
  };
}