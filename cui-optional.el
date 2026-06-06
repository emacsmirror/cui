;;; cui-optional.el --- Useful functions that not enabled by default.  -*- lexical-binding: t; -*-

;; Copyright (C) 2025 github.com/Anoncheg1
;; Author: <github.com/Anoncheg1,codeberg.org/Anoncheg>
;; SPDX-License-Identifier: AGPL-3.0-or-later

;;; License

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.

;; You should have received a copy of the GNU Affero General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; Licensed under the GNU Affero General Public License, version 3 (AGPLv3)
;; <https://www.gnu.org/licenses/agpl-3.0.en.html>

;;; Commentary:

;; Configuration for usage:

;; (require 'cui-optional)
;; (add-hook 'cui-block-after-chat-insertion-hook
;;          #'cui-optional-remove-headers-hook-function)
;; (add-hook 'cui-block-after-chat-insertion-hook
;;          #'cui-optional-remove-distant-empty-lines-hook-function)

(require 'cl-lib) ; Ensure cl-lib is loaded for cl-defun and cl-destructuring-bind
(require 'org)
(require 'cui-debug)

;;; Code:

;; -=-= remove-distant-empty-lines hook
(defun cui-optional-remove-distant-empty-lines (beg)
  "Remove excessibe empty lines from BEG to current position.
Don't remove empty lines that have more than two lines in a row before
 tham."
  (forward-line -1) ; precaution
  (let ((empty-line)
        (cl 0))
    (while (< beg (point))
      (when (eolp) ; empty line
        (when (and (<= cl 2) (> cl 0) empty-line)
          (save-excursion
            (goto-char empty-line)
            (delete-char 1)))
        (setq cl 0)
        (setq empty-line (point)))
      (setq cl (1+ cl ))
      (forward-line -1))))

(defun cui-optional-remove-distant-empty-lines-hook-function (&optional type _content before-pos stream)
  "Remove empty lines when there is too many of them.
Arguments TYPE CONTENT BEFORE-POS STREAM parameters described in
`cui-block-after-chat-insertion-hook' hook."
  (save-excursion
    (cui--debug "cui-optional-remove-distant-empty-lines-hook-function HOOK: %s %s %s %s"
                before-pos
                (point)
                type
                (type-of type))
    (if stream
        (cui-optional-remove-distant-empty-lines (save-excursion (cui-block-previous-message)))
      ;; else - not stream
      (cui-optional-remove-distant-empty-lines before-pos))))

;; -=-= remove-headers hook
(defun cui-optional-remove-headers (beg-pos end-pos)
  "Remove Org mode header prefixes, like ^**.
You may require this, because  LLMs frequently uses markdown for headers
that recognized in Org mode as headers, that break blocks.
Works at every line between BEG-POS and END-POS in the current buffer.
Uses `org-outline-regexp-bol' to match headers, respecting
user-configured prefixes."
  (interactive "r")
  (replace-regexp-in-region org-outline-regexp-bol "" beg-pos end-pos))


(defun cui-optional-remove-headers-hook-function (type _content before-pos _stream)
  "Ready for usage in `cui-block-after-chat-insertion-hook'.
Remove Org headers between BEFORE-POS and current position in current
 buffer buffer by adding space before it.
TYPE _CONTENT BEFORE-POS BUF parameters described in
`cui-block-after-chat-insertion-hook' hook.
Should be added the last to be executed first."
  (cui--debug "cui-optional-remove-headers-hook-function HOOK: %s %s %s %s"
              before-pos
              (point)
              type
              (type-of type))
  (when (member type '(text end))
    (save-excursion
      (let ((end (point-marker)))
        (goto-char before-pos)
        (while (re-search-forward org-outline-regexp-bol (marker-position end) t)
          (beginning-of-line)
          (insert " ") ; this effectively quote standard headers
          (end-of-line))))))

;; -=-= Markdown: folding _____TODO_______
;; TODO: - "#" may be inside markdown block!!!

;; (defun cui-optional--markdown-heading-p ()
;;   (save-excursion
;;     (forward-line 0)
;;     (and (looking-at cui-block--markdown-header-re)
;;          (not (cui-block--markdown-block-p)))))

;; (defun cui-optional--markdown-end-of-subtree ()
;;   "`org-end-of-subtree' uses `org-back-to-heading-or-point-min'.
;; Set cursor at first header after end.
;; Or set cursor at --- or at next chat prefix []: or at the end of chat
;;  block or end of buffer."
;;   (let* ((current-level (save-excursion
;;                          (beginning-of-line)
;;                          (if (looking-at "^\\(#+\\) ")
;;                              (length (match-string 1))
;;                            0)))
;;          (end-of-message (save-excursion
;;                            (cui-block--find-next-prev-region)))
;;          (page-sep (save-excursion
;;                      (catch 'result
;;                        (while (re-search-forward "^---" end-of-message t)
;;                          (when (save-excursion (cui-block--markdown-block-p))
;;                            (throw 'result (point))))
;;                        nil))) ; if not found, return nil

;;     (end-of-line)
;;     (if (and (derived-mode-p 'org-mode)
;;              (boundp 'cui-mode)
;;              (local-variable-p 'cui-mode)
;;              cui-mode
;;              (cui-block-p))
;;         (let (l
;;     (re-search-forward (format "^\\(#\\{1,%d\\}\\) " (1- current-level)) nil t)))
;;   ;; (if (org-before-first-heading-p)
;;   ;;     (goto-char (point-min))
;;   ;;   (org-back-to-heading invisible-ok))
;;   ;; )

;; (defun cui-optional--markdown-cycle ()
;; "'org-cycle-internal-local'
;; `org-fold-folded-p'."
;; (save-excursion
;;   (let ((eoh (line-end-position)) ; end of line
;;         (eos (save-excursion
;; 	       (cui-optional--markdown-end-of-subtree) ; set cursor at first header after end
;; 	       (unless (eobp) (forward-char -1))
;; 	       (point))))

;; )))

;; (defun cui-optional--markdown-end-of-subtree ()
;;   "`org-end-of-subtree'"
;;   (org-back-to-heading-or-point-min invisible-ok)

;;   )
;;;; provide
(provide 'cui-optional)
;;; cui-optional.el ends here
