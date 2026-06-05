;;; cui-tests-integration2.el --- AI blocks for org-mode. -*- lexical-binding: t; -*-

;; Copyright (C) 2025 github.com/Anoncheg1,codeberg.org/Anoncheg
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

;; (add-to-list 'load-path (expand-file-name "./"))
;; (eval-buffer)
;; (ert t)
;; emacs -Q --batch -l ert.el -l cui-debug.el -l cui-block.el -l cui-tests-block.el -l cui-tests-integration2.el -f ert-run-tests-batch-and-exit


;; (require 'cui-tests-block) ; cui-test-setup-buffer
(require 'ert)
(require 'cui-debug)
;; (require 'cui-tests-integration) ; `cui-tests--my-http-server-handler' and `cui-tests--create-http-service'
(require 'cui)
(require 'cui-prompt)
 ;; (require 'cl-macs) ; cl-letf

(defvar stub-retries nil)


;;; Code:

;;; - Help functions
(defun cui-test-setup-buffer (block-content &optional buf properties-alist)
  "Create ai BLOCK-CONTENT and optional PROPERTIES-ALIST.
In current buffer or in BUF.
PROPERTIES-ALIST should be an alist like ((property-name . \"value\")).
Set cursor at begining of buffer.
Returns a list (ELEMENT INFO-ALIST), where ELEMENT is the parsed Cui block
and INFO-ALIST is the parameters from its header."
  (with-current-buffer (or buf (current-buffer))
    (setq-local org-export-with-properties t) ; Ensure properties are considered
    (when properties-alist
      (dolist (prop properties-alist)
        (insert (format "#+PROPERTY: %s %s\n" (car prop) (cdr prop)))))
    (insert block-content)
    (goto-char (point-min))
    ;; Check if #+begin_ai exists to avoid search failure
    (unless (string-match-p "#\\+begin_ai" block-content)
      (error "Test setup failed: block-content does not contain '#+begin_ai'"))
    ;; Move point to the start of the AI block
    (unless (search-forward "#+begin_ai" nil t)
      (error "Failed to find '#+begin_ai' in buffer"))
    (beginning-of-line) ; Ensure point is at the start of the block
    (when (derived-mode-p 'org-mode)
      (let* ((element (org-element-at-point)))
        (unless (eq (org-element-type element) 'special-block)
          (error "No valid Cui block found at point"))
        element)) ; return
  ))

(defun my/cui-switch (&rest args)
  "For assiging to `cui-agent-call-function'."
  ;; element = (nth 1 args)
  (if (not (eql 'x (alist-get :c5 (cui-block-get-info (nth 1 args)) 'x)))
      (apply #'cui-prompt-request-chain-5 args)
    ;; else
    (if (not (apply #'cui-prompt-request-switch args))
        (apply #'cui-restapi-request-prepare  args)))
  t)


(defun cui-tests--my-http-server-handler (proc string)
  "(message \"in my-http-server-handler: %s\" string)"
  (setq string string) ; noqa Unused lexical argument
  (process-send-string
   proc
   "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"choices\":[{\"finish_reason\":\"length\",\"message\":{\"role\":\"assistant\",\"content\":\"Your question needs clarification.\"}}]}\n")
  (delete-process proc))


(defun cui-tests--run-http-service ()
  "to test: curl -v 127.0.0.1:9239"
  (unless (get-process "my-http-server")
    (make-network-process
     :name "my-http-server"
     :buffer "*my-http-server*"
     :family 'ipv4
     :service 9239
     ;; Try :host nil or "127.0.0.1" for clarity
     :host "127.0.0.1"
     :server t
     :filter 'cui-tests--my-http-server-handler))

;; (make-network-process :name "localhost" :host "127.0.0.1" :service 9239 :nowait t)

;; (delete-process "my-http-server")

  ;; (with-current-buffer (url-retrieve-synchronously "http://localhost:9239/")
  ;;   (prog1 (buffer-string)(kill-buffer)))

  ;; (with-current-buffer (url-retrieve-synchronously "http://127.0.0.1:9239/")
  ;;   (prog1 (buffer-string) (kill-buffer)))

  ;; (display-buffer (url-retrieve-synchronously "http://localhost:9239/"))


  ;; (url-retrieve
  ;;  "http://localhost:9239/"
  ;;  (lambda (status)
  ;;    (goto-char (point-min))
  ;;    ;; (re-search-forward "\r\n\r\n")
  ;;    (message "Server replied: %s" (buffer-substring (point-min) (point-max)))))
  )


(defun cui-tests--stop-http-service ()
  (when (get-process "my-http-server")
    (delete-process "my-http-server")))

;;; - Integration test: test 1
(defun cui-tests-integration2--cui-restapi-request-llm-retries-stub1( func-call &rest args)
;; (cl-defun cui-tests-integration2--cui-restapi-request-llm-retries-stub (service model timeout callback &optional &key retries prompt messages header-marker max-tokens temperature top-p frequency-penalty presence-penalty)
  (cui--debug "Stub for cui-restapi-request-llm-retries %s %s" stub-retries args)

  (setq stub-retries (1+ stub-retries))
  ;; (sleep-for 0.5) ; allow
  (apply func-call args)
  ;; (cui--debug "Stub for cui-restapi-request-llm-retries stop!!")
  ;; (cui-restapi-stop-all-url-requests)
  ;; (cui-restapi-request-llm-retries service model timeout callback
  ;;                                  :retries retries
  ;;                                  :prompt prompt
  ;;                                  :messages messages
  ;;                                  :max-tokens max-tokens
  ;;                                  :header-marker header-marker
  ;;                                  :temperature temperature
  ;;                                  :top-p top-p
  ;;                                  :frequency-penalty frequency-penalty
  ;;                                  :presence-penalty presence-penalty)
  )


(ert-deftest cui-tests-integllm-test1 ()
  ":chain test with `cui-restapi-request-llm-retries'."
  ;; - 1) Run HTTP-SERVICE
  (condition-case nil
      (cui-tests--stop-http-service)
    (error nil))

  (cui-tests--run-http-service)
  ;; - 2) add Stub
  (let ((temp-buffer (generate-new-buffer "ttemp" t)))

    (with-current-buffer temp-buffer
      (org-mode)
      (cui-mode)
      (cui-test-setup-buffer "#+begin_ai :chain :stream nil :service test :model none\nTest content\n#+end_ai")
      (let ((cui-restapi-con-endpoints (list :test "http://localhost:9239/v1/chat/completions"))
            (cui-restapi-con-token "test")
            (cui-timers-duration 3)
            (cui-timers-retries 3)
            ;; (cui-agent-call-function #'my/cui-switch)
            (stub-retries 0))

        ;; (print (list "cui-timers-duration" cui-timers-duration (current-buffer)))
        (unwind-protect
            (progn
              (advice-add 'cui-restapi-request-llm-retries :around #'cui-tests-integration2--cui-restapi-request-llm-retries-stub1)
              (sleep-for 0.5) ; required
              ;; - 3) Run request (with sleep to preserve let-s)
              (org-ctrl-c-ctrl-c)

              ;; )
              ;; (error
              ;;  ;; (print (list "error! delete-process" (buffer-substring-no-properties (line-beginning-position) (line-end-position) )))
              ;;  ;; (cui-tests--stop-http-service)
              ;;  (signal (car err) (cdr err)))) ; re-signal error (does not suppress)
              (sleep-for (* cui-timers-retries cui-timers-duration))
              (print (list (equal stub-retries 3)
                           (equal cui-timers--global-progress-timer nil)
                           (equal cui-timers--global-progress-reporter nil)))
              (should (equal stub-retries 3))
              (should (equal cui-timers--global-progress-timer nil))
              (should (equal cui-timers--global-progress-reporter nil))
              (goto-char 1)
              (let* ((v (cui-block-msgs--collect-chat-messages-from-string (cui-block-get-content (cui-block-p))))
                     (p0 (seq-elt (cui-block-msgs--collect-chat-messages-from-string (cui-block-get-content (cui-block-p)))
                                  0))
                     (p1 (seq-elt (cui-block-msgs--collect-chat-messages-from-string (cui-block-get-content (cui-block-p)))
                                  1)))
                (should (equal (plist-get p0 :role) 'user))
                (should (string-equal (plist-get p0 :content) "Test content"))
                (should (equal (plist-get p1 :role) 'assistant))
                )
               (advice-remove 'cui-restapi-request-llm-retries  #'cui-tests-integration2--cui-restapi-request-llm-retries-stub1))))

      ;; (run-at-time 1 nil (lambda (buf) (with-current-buffer buf
      ;;                                    ;; (print "#+begin_ai :stream nil :service test :model none\nTest content\n\n[AI]: Your question needs clarification.\n\n[ME]:\n#+end_ai")
      ;;                                    ;; (print (list "wtf" (buffer-substring-no-properties (point-min) (point-max) )
      ;;                                    ;; (message "A:%S\nB:%S"
      ;;                                    ;; (print (list "cui-block-after-chat-insertion-hook" cui-block-after-chat-insertion-hook))
      ;;                                    ;; (message "A:%S\nB:%S" (buffer-substring-no-properties (point-min) (point-max) )
      ;;                                    ;;          "#+begin_ai :stream nil :service test :model none\nTest content\n\n[AI]: Your question needs clarification.\n\n[ME]: \n#+end_ai")
      ;;                                    (should (string-equal
      ;;                                             (buffer-substring-no-properties (point-min) (point-max) )
      ;;                                             "#+begin_ai :stream nil :service test :model none\nTest content\n\n[AI]: Your question needs clarification.\n\n[ME]: \n#+end_ai")
      ;;                                            ))
      ;;                      (delete-process "my-http-server"))
      ;;              temp-buffer)
      )))

;;; - Integration test: test 2


(defun cui-tests-integration2--cui-restapi-request-llm-retries-stub2( func-call &rest args)
;; (cl-defun cui-tests-integration2--cui-restapi-request-llm-retries-stub (service model timeout callback &optional &key retries prompt messages header-marker max-tokens temperature top-p frequency-penalty presence-penalty)
  ;; (cui--debug "Stub for cui-restapi-request-llm-retries %s %s" stub-retries args)

  (setq stub-retries (1+ stub-retries))
  ;; (sleep-for 0.5) ; allow
  (apply func-call args)
  ;; (cui--debug "Stub for cui-restapi-request-llm-retries stop!!")
  (cui-restapi-stop-all-url-requests)
  ;; (cui-restapi-request-llm-retries service model timeout callback
  ;;                                  :retries retries
  ;;                                  :prompt prompt
  ;;                                  :messages messages
  ;;                                  :max-tokens max-tokens
  ;;                                  :header-marker header-marker
  ;;                                  :temperature temperature
  ;;                                  :top-p top-p
  ;;                                  :frequency-penalty frequency-penalty
  ;;                                  :presence-penalty presence-penalty)
  )



(ert-deftest cui-tests-integllm-test2 ()
  ":chain with `cui-restapi-request-llm-retries'"
  ;; - 1) Run HTTP-SERVICE
  (condition-case nil
      (cui-tests--stop-http-service)
    (error nil))

  (cui-tests--run-http-service)
  ;; - 2) add Stub
  (let ((temp-buffer (generate-new-buffer "ttemp" t)))
    (advice-add 'cui-restapi-request-llm-retries :around #'cui-tests-integration2--cui-restapi-request-llm-retries-stub2)
    (with-current-buffer temp-buffer
      (org-mode)
      (cui-mode)
      (cui-test-setup-buffer "#+begin_ai :chain :stream nil :service test :model none\nTest content\n#+end_ai")
      (let ((cui-restapi-con-endpoints (list :test "http://localhost:9239/v1/chat/completions"))
            (cui-restapi-con-token "test")
            (cui-timers-duration 3)
            (cui-timers-retries 3)
            ;; (cui-agent-call-function #'my/cui-switch)
            (stub-retries 0)
            )
        (unwind-protect
            (progn

        (print (list "cui-timers-duration" cui-timers-duration (current-buffer)))
        ;; (condition-case err
            (progn
              (sleep-for 0.5) ; required
              ;; - 3) Run request (with sleep to preserve let-s)
              (org-ctrl-c-ctrl-c)

              )
          ;; (error
          ;;  ;; (print (list "error! delete-process" (buffer-substring-no-properties (line-beginning-position) (line-end-position) )))
          ;;  ;; (cui-tests--stop-http-service)
          ;;  (signal (car err) (cdr err)))) ; re-signal error (does not suppress)
        (sleep-for (* cui-timers-retries cui-timers-duration))
        (print (list (equal stub-retries 1)
                     (equal cui-timers--global-progress-timer nil)
                     (equal cui-timers--global-progress-reporter nil)))
        (should (equal stub-retries 1))
        (should (equal cui-timers--global-progress-timer nil))
        (should (equal cui-timers--global-progress-reporter nil))
        )
        (advice-remove 'cui-restapi-request-llm-retries  #'cui-tests-integration2--cui-restapi-request-llm-retries-stub2))

      ;; (run-at-time 1 nil (lambda (buf) (with-current-buffer buf
      ;;                                    ;; (print "#+begin_ai :stream nil :service test :model none\nTest content\n\n[AI]: Your question needs clarification.\n\n[ME]:\n#+end_ai")
      ;;                                    ;; (print (list "wtf" (buffer-substring-no-properties (point-min) (point-max) )
      ;;                                    ;; (message "A:%S\nB:%S"
      ;;                                    ;; (print (list "cui-block-after-chat-insertion-hook" cui-block-after-chat-insertion-hook))
      ;;                                    ;; (message "A:%S\nB:%S" (buffer-substring-no-properties (point-min) (point-max) )
      ;;                                    ;;          "#+begin_ai :stream nil :service test :model none\nTest content\n\n[AI]: Your question needs clarification.\n\n[ME]: \n#+end_ai")
      ;;                                    (should (string-equal
      ;;                                             (buffer-substring-no-properties (point-min) (point-max) )
      ;;                                             "#+begin_ai :stream nil :service test :model none\nTest content\n\n[AI]: Your question needs clarification.\n\n[ME]: \n#+end_ai")
      ;;                                            ))
      ;;                      (delete-process "my-http-server"))
      ;;              temp-buffer)
      ))))

(provide 'cui-tests-integration2)

;;; cui-tests-integration2.el ends here
