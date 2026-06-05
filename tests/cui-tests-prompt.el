;;; cui-tests-prompt.el --- Tests. -*- lexical-binding: t; -*-

;; Copyright (c) 2025 github.com/Anoncheg1,codeberg.org/Anoncheg
;; SPDX-License-Identifier: AGPL-3.0-or-later
;; Author: github.com/Anoncheg1,codeberg.org/Anoncheg

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
;;

(require 'ert)
(require 'cui-prompt)
(defvar ert-enabled nil)
;; (eval-buffer)
;; (ert t)
;; emacs -Q --batch -l ert.el -l cui-debug.el -l cui-block.el -l cui-block-tags.el -l cui-timers.el -l cui-async1.el -l cui-restapi.el -l cui-prompt.el -l ./tests/cui-tests-prompt.el -f ert-run-tests-batch-and-exit

;;; Code:

;; -=-= For `cui-prompt-collect-chat-research-steps-prompt'

(ert-deftest cui-tests-prompt--collect-chat-research-steps-prompt1 ()
  (should
   (equal
    (let ((cui-restapi-add-max-tokens-recommendation t)
          (max-tokens 200))
      (cui-prompt-collect-chat-research-steps-prompt cui-prompt-chain-list
                                             0
                                             (cui-block-msgs--collect-chat-messages-from-string
                                              "[ME:]How to make coffe?\n[AI]: IDK.")
                                             ""
                                             max-tokens))
      (vector (list :role 'system :content (concat (nth 0 cui-prompt-chain-list) " " (cui-restapi--get-length-recommendation 200)))
                    (list :role 'user :content "How to make coffe?")
                    (list :role 'assistant :content "IDK.")))))

(ert-deftest cui-tests-prompt--collect-chat-research-steps-prompt2 ()
  (should
   (equal
    (cui-prompt-collect-chat-research-steps-prompt cui-prompt-chain-list
                                                   1
                                                   (cui-block-msgs--collect-chat-messages-from-string "[ME:]How to make coffe?\n[AI]: IDK.")
                                                   "Be helpful.")
    (vector (list :role 'system :content (concat "Be helpful. " (nth 0 cui-prompt-chain-list)))
            (list :role 'user :content "How to make coffe?")
            (list :role 'assistant :content "IDK.")
            (list :role 'system :content (nth 1 cui-prompt-chain-list))))))

(ert-deftest cui-tests-prompt--collect-chat-research-steps-prompt3 ()
  (should
   (let (cui-restapi-add-max-tokens-recommendation)
     (equal
      (cui-prompt-collect-chat-research-steps-prompt cui-prompt-chain-list
                                                     2
                                                     (cui-block-msgs--collect-chat-messages-from-string (concat "[ME:]How to make coffe?\n[AI]: IDK.\n[SYS]: " (nth 1 cui-prompt-chain-list) "\n[AI]: IDK.")))
      (vector (list :role 'system :content (nth 0 cui-prompt-chain-list))
              (list :role 'user :content "How to make coffe?")
              (list :role 'assistant :content "IDK.")
              (list :role 'system :content (nth 1 cui-prompt-chain-list))
              (list :role 'assistant :content "IDK.")
              (list :role 'system :content (nth 2 cui-prompt-chain-list)))))))

(ert-deftest cui-tests-prompt--collect-chat-research-steps-prompt4 ()
  (should
   (let (cui-restapi-add-max-tokens-recommendation)
     (equal
      (cui-prompt-collect-chat-research-steps-prompt cui-prompt-chain-list
                                                     0
                                                     (cui-block-msgs--collect-chat-messages-from-string "[ME:]How to make coffe?\n[AI]: IDK."))
      (vector (list :role 'system :content (nth 0 cui-prompt-chain-list))
              (list :role 'user :content "How to make coffe?")
              (list :role 'assistant :content "IDK."))))))

;; -=-= provide
(provide 'cui-tests-prompt)

;;; cui-tests-prompt.el ends here
