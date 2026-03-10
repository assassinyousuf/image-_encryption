# image-_encryption

An image encryption project.

---

## How to Push Files to This Repository from VS Code

Follow the steps below to clone the repository, make changes, and push them back using VS Code.

### Prerequisites

- [Git](https://git-scm.com/downloads) installed on your machine
- [Visual Studio Code](https://code.visualstudio.com/) installed
- A [GitHub](https://github.com) account with access to this repository

---

### Step 1 — Clone the Repository

1. Open VS Code.
2. Press `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (macOS) to open the Command Palette.
3. Type **Git: Clone** and select it.
4. Paste the repository URL:
   ```
   https://github.com/assassinyousuf/image-_encryption.git
   ```
5. Choose a local folder where you want to save the project.
6. When prompted, click **Open** to open the cloned repository in VS Code.

---

### Step 2 — Add or Edit Files

Make your changes inside the cloned project folder — add new files, edit existing ones, etc.

---

### Step 3 — Stage Your Changes

1. Click the **Source Control** icon in the left sidebar (or press `Ctrl+Shift+G`).
2. You will see a list of changed files under **Changes**.
3. Click the **+** (plus) icon next to each file you want to include, or click the **+** next to **Changes** to stage all files at once.

---

### Step 4 — Commit Your Changes

1. In the **Source Control** panel, type a short commit message in the text box at the top (e.g., `Add encryption module`).
2. Press `Ctrl+Enter` (Windows/Linux) or `Cmd+Enter` (macOS), or click the **✓ Commit** (checkmark) button to commit your staged changes.

---

### Step 5 — Push to GitHub

1. After committing, click the **...** (More Actions) menu in the Source Control panel and select **Push**, **or** click the sync/push button (↑) in the bottom status bar.
2. If prompted, sign in to GitHub through VS Code.
3. Your files are now pushed to the repository on GitHub.

---

### Tip — Using the Integrated Terminal

You can also push files using VS Code's built-in terminal (`` Ctrl+` ``):

```bash
git add .
git commit -m "Your commit message"
git push
```

---

### Troubleshooting

| Problem | Solution |
|---|---|
| `git push` is rejected | Run `git pull` first to sync with the remote, then push again. |
| Permission denied | Make sure you have collaborator access to the repository. |
| Not authenticated | Run `git config --global user.email "you@example.com"` and `git config --global user.name "Your Name"`, then retry. |