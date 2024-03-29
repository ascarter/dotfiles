;; Put customizations in alternate file since these are per-machine
(setq custom-file "~/.config/emacs/custom.el")
(unless (file-exists-p custom-file)
  (make-empty-file custom-file))
(load-file custom-file)

;; Enable MELPA repository
;; Configure package.el to include MELPA.
(require 'package)
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/"))
(add-to-list 'package-archives '("nongnu" . "https://elpa.nongnu.org/nongnu/"))
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(setq package-native-compile t)

;; Auto-install use-package
(setq use-package-always-ensure t)
(unless (package-installed-p 'use-package)
  (message "Refreshing package contents")
  (unless package-archive-contents (package-refresh-contents))
  (package-install 'use-package))
(eval-when-compile (require 'use-package))

;; Enable hiding minor modes
(use-package diminish)

;; Theme
(use-package modus-themes
  :config
  (setq modus-themes-italic-constructs t
	modus-themes-bold-constructs t)
  (setq modus-themes-common-palette-overrides
	modus-themes-preset-overrides-intense))

;; Automatically adjust for light/dark modes
(use-package auto-dark
  :diminish
  :config
  (setq	auto-dark-allow-osascript t
	auto-dark-dark-theme 'modus-vivendi
	auto-dark-light-theme 'modus-operandi)
  (auto-dark-mode t))

;; GUI mode - turn off toolbar and set default fonts
(when (window-system)
  (scroll-bar-mode -1)
  (tool-bar-mode -1)
  (tooltip-mode -1)
  ;; Set default font
  (pcase system-type
    ('darwin (set-frame-font "SF Mono 13" nil t))
    ((or 'gnu/linux 'windows-nt) (set-frame-font "Noto Sans Mono 13" nil t)))
  ;; Set transparency for selected/unselected frames
  (set-frame-parameter (selected-frame) 'alpha '(96 . 90))
  (add-to-list 'default-frame-alist '(alpha . (96 . 90))))

;; Terminal mode - turn off menu bar and enable xterm mouse mode
(when (not window-system)
  (menu-bar-mode -1)
  (xterm-mouse-mode 1))

;; Show buffers in window
;;(setq tab-line-tabs-function 'tab-line-tabs-mode-buffers)
(global-tab-line-mode 1)

;; Show tab bar automatically when more than 1 tab
(setq tab-bar-show t)

;; Set current line highlighting
(global-hl-line-mode t)

;; Show time but not load
(setq display-time-24hr-format 1
      display-time-default-load-average nil)
(display-time-mode 1)

(setq-default cursor-type 'bar)
(setq sentence-end-double-space nil
      use-short-answers t
      confirm-kill-processes nil
      ;; inhibit-startup-screen t
      ;; initial-scratch-message nil
 )
(global-display-line-numbers-mode t)
(column-number-mode)
(delete-selection-mode t)

;; Disable backups
(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil)

;; Remove trailing whitespace on save
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; Key bindings
(bind-key* "C-c /" #'comment-dwim)
(bind-key "C-." #'completion-at-point)

;; Enable macOS behaviors
(when (window-system)
  (when (eq system-type 'darwin)
    ;; Cmd+up/down arrow to beginning/end of buffer
    (bind-key "s-<up>" #'beginning-of-buffer)
    (bind-key "s-<down>" #'end-of-buffer)
    ;; Cmd+w close buffer instead of entire frame
    (bind-key "s-w" #'kill-this-buffer)))

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
  ;; Copy the current buffer file name to the clipboard.
  ;; The path will be relative to the project's root directory, if set.
  ;; Invoking with a prefix argument copies the full path."
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

;; Use magit for git version control
(use-package magit)

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
  (project-vc-merge-submodules nil))

;; Dash
(when (eq system-type 'darwin)
  (use-package dash-at-point
    :bind ("C-c d" . dash-at-point)))

;; Markdown (default to GFM)
(use-package markdown-mode
  :ensure t
  :mode ("\\.\\(?:md\\|markdown\\|mkd\\|mdown\\|mkdn\\|mdwn\\)" . gfm-mode)
  :init (setq markdown-command "cmark-gfm"
	      markdown-open-command "~/.local/bin/marked"
	      markdown-live-preview-delete-export 'delete-on-export))

;; Ruby
(use-package chruby)

;; Lua
(use-package lua-mode)
