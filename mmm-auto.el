;;; mmm-auto.el --- loading and enabling MMM Mode automatically

;; Copyright (C) 2000 by Michael Abraham Shulman

;; Author: Michael Abraham Shulman <mas@kurukshetra.cjb.net>
;; Version: $Id: mmm-auto.el,v 1.9 2000/06/29 18:23:41 mas Exp $

;;{{{ GPL

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;}}}

;;; Commentary:

;; This file contains functions and hooks to load and enable MMM Mode
;; automatically. It sets up autoloads for the main MMM Mode functions
;; and interactive commands, and also sets up MMM Global Mode.

;;{{{ Comments on MMM Global Mode

;; This is a kludge borrowed from `global-font-lock-mode'.  The idea
;; is the same: we have a function (here `mmm-mode-on-maybe') that we
;; want to be run whenever a major mode starts.  Unfortunately, there
;; is no hook (like, say `major-mode-hook') that all major modes run
;; when they are finished.  `post-command-hook', however, is run after
;; *every* command, so we do our work in there.  (Actually, using
;; `post-command-hook' is even better than being run by major mode
;; functions, since it is run after all local variables and text are
;; loaded, which may not be true in certain cases for the other.)

;; In order to do this magic, we rely on the fact that there *is* a
;; hook that all major modes run when *beginning* their work. They
;; call `kill-all-local-variables' (unless they are broken), which in
;; turn runs `change-major-mode-hook'.  So we add a function to *that*
;; hook which saves the current buffer and temporarily adds a function
;; to `post-command-hook' which processes that buffer.

;; Actually, in the interests of generality, what that function does
;; is run the hook `mmm-major-mode-hook'. Our desired function
;; `mmm-mode-on-maybe' is then added to that hook. This way, if the
;; user wants to run something else on every major mode, they can just
;; add it to `mmm-major-mode-hook' and take advantage of this hack.

;;}}}

;;; Code:

(require 'cl)
(require 'mmm-vars)

;;{{{ Autoloads

;; To shut up the byte compiler.
(eval-and-compile
  (autoload 'mmm-mode-on "mmm-mode" "Turn on MMM Mode. See `mmm-mode'.")
  (autoload 'mmm-mode "mmm-mode"
    "Minor mode to allow multiple major modes in one buffer.
Without ARG, toggle MMM Mode. With ARG, turn MMM Mode on iff ARG is
positive and off otherwise." t))

(autoload 'mmm-ify-by-class "mmm-cmds" "" t)
(autoload 'mmm-ify-by-regexp "mmm-cmds" "" t)
(autoload 'mmm-ify-region "mmm-cmds" "" t)
(autoload 'mmm-parse-buffer "mmm-cmds" "" t)
(autoload 'mmm-parse-region "mmm-cmds" "" t)
(autoload 'mmm-parse-block "mmm-cmds" "" t)
(autoload 'mmm-clear-current-region "mmm-cmds" "" t)
(autoload 'mmm-reparse-current-region "mmm-cmds" "" t)
(autoload 'mmm-end-current-region "mmm-cmds" "" t)
(autoload 'mmm-insertion-help "mmm-cmds" "" t)
(autoload 'mmm-insert-region "mmm-cmds" "" t)

;;}}}
;;{{{ MMM Global Mode

(defvar mmm-changed-buffers-list ()
  "Buffers that need to be checked for running the major mode hook.")

(defun mmm-major-mode-change ()
  "Add this buffer to `mmm-changed-buffers-list' for checking.
When the current command is over, MMM Mode will be turned on in this
buffer depending on the value of `mmm-global-mode'.  Actually,
everything in `mmm-major-mode-hook' will be run."
  (and (boundp 'mmm-mode)
       mmm-mode
       (mmm-mode-off))
  (add-to-list 'mmm-changed-buffers-list (current-buffer))
  (add-hook 'post-command-hook 'mmm-check-changed-buffers))

(add-hook 'change-major-mode-hook 'mmm-major-mode-change)

(defun mmm-check-changed-buffers ()
  "Run major mode hook for the buffers in `mmm-changed-buffers-list'."
  (remove-hook 'post-command-hook 'mmm-check-changed-buffers)
  (dolist (buffer mmm-changed-buffers-list)
    (and (not (window-minibuffer-p (get-buffer-window buffer)))
         (buffer-live-p buffer)
         (mmm-run-major-mode-hook buffer)))
  (setq mmm-changed-buffers-list '()))

(defun mmm-mode-on-maybe ()
  "Conditionally turn on MMM Mode.
Turn on MMM Mode if `global-mmm-mode' is non-nil and there are classes
to apply, or always if `global-mmm-mode' is t."
  (cond ((eq mmm-global-mode t) (mmm-mode-on))
        ((not mmm-global-mode))
        ((mmm-get-all-classes) (mmm-mode-on))))

(add-hook 'mmm-major-mode-hook 'mmm-mode-on-maybe)

(defalias 'mmm-add-find-file-hooks 'mmm-add-find-file-hook)
(defun mmm-add-find-file-hook ()
  "Equivalent to \(setq mmm-global-mode 'maybe).
This function is deprecated and may be removed in future."
  (message "Warning: `mmm-add-find-file-hook' is deprecated.")
  (setq mmm-global-mode 'maybe))

;;}}}

(provide 'mmm-auto)

;;; mmm-auto.el ends here