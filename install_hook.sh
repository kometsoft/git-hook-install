#!/bin/bash

check_git_repository() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Current directory is not a Git repository."
    exit 1
  fi
}

prompt_for_branch() {
  read -p "Enter the preferred branch to trigger the hook (default: main): " branch
  branch=${branch:-"main"}
  if [[ -z $branch ]]; then
    echo "Error: Branch cannot be empty."
    prompt_for_branch
  fi
}

prompt_for_command() {
  echo "Enter the command to run after pulling. Press Ctrl+D on an empty line to finish."
  
  command=""
  while IFS= read -r line; do
    if [[ -z $line ]]; then
      break
    fi
    command+="$line"$'\n'
  done
  
  command=${command:-""}
}

install_git_hook() {
  hook_type=${1:-"post-receive"}
  hook_file=".git/hooks/$hook_type"

  if [[ -f $hook_file ]]; then
    read -p "A $hook_type hook file already exists. Do you want to overwrite it? (y/n): " overwrite
    if [[ $overwrite != "y" ]]; then
      echo "Installation aborted."
      exit 0
    fi
  fi

  # Create or overwrite the post-receive hook file
  cat > "$hook_file" <<EOF
#!/bin/bash
while read oldrev newrev refname; do
  if [[ \$refname = "refs/heads/$branch" ]]; then
    cd \$(git rev-parse --show-toplevel)

    git pull

$(sed 's/^/    /' <<< "$command")
    echo "\$(git rev-parse --show-toplevel)/$hook_type hook executed!"
  fi
done
EOF

  # Make the hook file executable
  chmod +x "$hook_file"

  echo "Hook [$hook_file] installed successfully!"
}

echo "Git Hook (post-receive) Installation Script"

check_git_repository

prompt_for_branch

prompt_for_command

install_git_hook
