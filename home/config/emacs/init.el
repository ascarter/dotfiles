;; Enable MELPA repository
;; Configure package.el to include MELPA.
(require 'package)
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/"))
(add-to-list 'package-archives '("nongnu" . "https://elpa.nongnu.org/nongnu/"))
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(setq package-native-compile t)
(setq use-package-always-ensure t)
(unless (package-installed-p 'use-package)
  (message "Refreshing package contents")
  (unless package-archive-contents (package-refresh-contents))
  (package-install 'use-package)
  )

(eval-when-compile (require 'use-package))

;; Setup UI
(when (window-system)
  ;;(load-theme 'modus-vivendi)
  ;; Automatically adjust for light/dark modes
  (use-package auto-dark
    :config
    (setq auto-dark-dark-theme 'modus-vivendi)
    (setq auto-dark-light-theme 'modus-operandi)
    (auto-dark-mode t)
    )
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (tooltip-mode -1)
  ;; Set current line highlighting
  (require 'hl-line)
  (add-hook 'prog-mode-hook #'hl-line-mode)
  (add-hook 'text-mode-hook #'hl-line-mode)
  ;; (global-hl-line-mode)
  ;; Set default font
  (pcase system-type
    ('darwin (set-frame-font "SF Mono 13" nil t))
    ((or 'gnu/linux 'windows-nt) (set-frame-font "IBM Plex Mono 13" nil t))
    )
  )
(setq-default cursor-type 'bar)
(setq
;; inhibit-startup-screen t
;; initial-scratch-message nil
 sentence-end-double-space nil
 use-short-answers t
 confirm-kill-processes nil
 )
(global-display-line-numbers-mode t)
(column-number-mode)
(delete-selection-mode t)

;; Disable backups
(setq
 make-backup-files nil
 auto-save-default nil
 create-lockfiles nil
 )

;; Key bindings
(bind-key* "C-c /" #'comment-dwim)
(bind-key "C-." #'completion-at-point)

;; Cmd+w close buffer instead of entire frame
(bind-key "s-w" #'kill-this-buffer)

;; Right-click menu behavior
(context-menu-mode)
(bind-key "C-c C-m" #'tmm-menubar)

;; Edit init.el
(defun open-init-file()
  "Open init.el"
  (interactive)
  (find-file "~/.config/dotfiles/home/config/emacs/init.el"))
(bind-key "C-c e" #'open-init-file)

;; Copy filename to clipboard
(defun copy-file-name-to-clipboard (do-not-strip-prefix)
  "Copy the current buffer file name to the clipboard. The path will be relative to the project's root directory, if set. Invoking with a prefix argument copies the full path."
  (interactive "P")
  (letrec
      ((fullname (if (equal major-mode 'dired-mode) default-directory (buffer-file-name)))
       (root (project-root (project-current)))
       (relname (file-relative-name fullname root))
       (should-strip (and root (not do-not-strip-prefix)))
       (filename (if should-strip relname fullname)))
    (kill-new filename)
    (message "Copied buffer file name '%s' to the clipboard." filename)))
(bind-key "C-c p" #'copy-file-name-to-clipboard)

;; Switch to session scratch buffer
(defun switch-to-scratch-buffer ()
  "Switch to the current session's scratch buffer."
  (interactive)
  (switch-to-buffer "*scratch*"))
(bind-key "C-c a s" #'switch-to-scratch-buffer)

;; Use project.el for project view
(use-package project
  :pin gnu
  :bind (("C-c k" . #'project-kill-buffers)
         ("C-c m" . #'project-compile)
         ("C-x f" . #'find-file)
         ("C-c f" . #'project-find-file)
         ("C-c F" . #'project-switch-project))
  :custom
  (project-switch-commands
   '((project-find-file "Find file")
     (magit-project-status "Magit" ?g)
     (deadgrep "Grep" ?h)))
  (compilation-always-kill t)
  (project-vc-merge-submodules nil)
  )

;; Dash
(when (eq system-type 'darwin)
  (use-package dash-at-point
    :bind ("C-c d" . dash-at-point))
  )