;;; cui-tests-msgs.el --- Tests. -*- lexical-binding: t; -*-

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
;; $ emacs -Q --batch -l ert.el -l cui-debug.el -l cui-block-tags.el -l cui-block.el -l cui-timers.el -l cui-async1.el -l cui-restapi.el -l ./tests/cui-tests-restapi.el -f ert-run-tests-batch-and-exit
;; or

;; (eval-buffer)
;; (ert t)


;;; Code:
;; -=-= imports
(require 'ert)
(require 'cui-block)
(require 'cui-block-tags)
(require 'cui-block-msgs)
(require 'cui-debug)

(defvar ert-enabled nil)

;; -=-= Test: `cui-block-msgs--get-chat-messages-positions', `cui-block-msgs--collect-chat-messages-from-string'
(ert-deftest cui-tests-block-msgs--chat-messages-tests ()
  (let ((payload "text before
as
[AI]: some1
[AI]:
[AI]: some2[ME:]")
        ;; (correct-sep '((:role 'user :content "text before\nas") (:role 'assistant :content "some1") (:role 'assistant :content "some2"))
        (correct-sep '((:role user :content "text before\nas") (:role assistant :content "some1") (:role assistant :content "some2[ME:]")))
        (correct-merged '[(:role user :content "text before\nas") (:role assistant :content "some1\nsome2[ME:]")])
        res)
    (with-temp-buffer
      (insert payload)
      (setq res (cui-block-msgs--parse-part (point-min) 10))
      (should (equal res '(:role user :content "text befo")))
      (setq res (let ((lst (cui-block--get-chat-messages-positions (point-min) (point-max) cui-block--chat-prefixes-re))
                      (results '()))
                  (while (and lst (cdr lst))
                    (push (cui-block-msgs--parse-part (car lst) (cadr lst)) results) ; parse current block
                    (setq lst (cdr lst)))
                  (nreverse (remove nil results))))
      (should (equal correct-sep res))
      (setq res (cui-block-msgs--collect-chat-messages-from-string payload))
      (should (equal res correct-sep))
      (setq res (vconcat (cui-block-msgs--merge-by-role res)))
      (should (equal res correct-merged)))))

;; -=-= Test: `cui-block-msgs--parse-part'
(ert-deftest cui-tests-block-msgs--parse-part ()
  (should (equal (with-temp-buffer
                   (insert "ss")
                   (cui-block-msgs--parse-part 1 (point)))
                 '(:role user :content "ss")))
  (should (not (with-temp-buffer
                 (insert "")
                 (cui-block-msgs--parse-part 1 (point)))))
  (should (not (with-temp-buffer
                 (insert "[AI:] ")
                 (cui-block-msgs--parse-part 1 (point)))))
  (should-error (with-temp-buffer
                  (insert "[AI:] vv\n[ME:] zz\n")
                  (cui-block-msgs--parse-part 1 (point)))
                :type 'error)
  (should (with-temp-buffer
            (insert "[AI:] vv\n")
            (let ((p (point))
                  res)
              (insert "[ME:] zz\n")
              (setq res (cui-block-msgs--parse-part 1 p))
              (equal res
                     '(:role assistant :content "vv"))
              (setq res (cui-block-msgs--parse-part p (point)))
              (equal res
                     '(:role user :content "zz"))))))


;; -=-= Test: `cui-block-msgs--merge-by-role'
(ert-deftest cui-tests-block-msgs--cui-block--merge-consecutive-messages-by-role1()
  (should (equal (let ((parts
         (list
          (list :role 'system :content nil )
          (list :role 'user :content "Hi." )
          (list :role 'user :content "How are you?" )
          (list :role 'assistant :content nil)
          (list :role 'assistant :content "I'm fine.")
          (list :role 'user :content "Hi." )
          (list :role 'user :content nil ))))
    (cui-block-msgs--merge-by-role parts "::" ))
                 '((:role user :content "Hi.::How are you?") (:role assistant :content "I'm fine.") (:role user :content "Hi.")))))

(ert-deftest cui-tests-block-msgs--cui-block--merge-consecutive-messages-by-role2()
  (should (equal (let ((parts
         (list
          (list :role 'system :content "Hi." )
          (list :role 'user :content "How are you?" )
          (list :role 'assistant :content nil)
          (list :role 'assistant :content "I'm fine.")
          (list :role 'user :content "Hi." )
          (list :role 'user :content nil ))))
  (cui-block-msgs--merge-by-role parts "::"))
                 '((:role system :content "Hi.") (:role user :content "How are you?") (:role assistant :content "I'm fine.") (:role user :content "Hi.")))))

;; -=-= Test: `cui-block-msgs--collect-chat-messages-from-string'
(ert-deftest cui-tests-block-msgs--collect-chat-messages()
  (should (equal (let ((parts
                        (list
                         (list :role 'user :content "Hi." )
                         (list :role 'user :content "How are you?" )
                         (list :role 'assistant :content "I'm fine.")
                         (list :role 'user :content "Hi." )))
                       res)
                   (cui-block-msgs--collect-chat-messages-from-string (cui-block-msgs--stringify-chat-messages (apply #'vector parts))))
                 '((:role user :content "Hi.")
                   (:role user :content "How are you?")
                   (:role assistant :content "I'm fine.")
                   (:role user :content "Hi.")))))

;; -=-= Test: `cui-block-msgs--collect-chat-messages-from-string'
(ert-deftest cui-tests-block-msgs--collect-chat-messages-from-string ()
  ;; deal with unspecified prefix
  ;; (should
  ;;  (equal
  ;;   (let ((test-string "\ntesting\n  [ME]: foo bar baz zorrk\nfoo\n[AI]: hello hello[ME]: "))
  ;;     ;; (cui-restapi--collect-chat-messages test-string))
  ;;     (cui-block-msgs--collect-chat-messages-from-string test-string))

  ;;   '[(:role user :content "testing\nfoo bar baz zorrk\nfoo")
  ;;     (:role assistant :content "hello hello")]))

  ;; sys prompt
  (should
   (equal
    (let ((test-string "[SYS]: system\n[ME]: user\n[AI]: assistant"))
      (cui-block-msgs--collect-chat-messages-from-string test-string))
    '((:role system :content "system")
      (:role user :content "user")
      (:role assistant :content "assistant"))))

  ;; sys prompt intercalated
  (should
   (equal
    (let ((test-string "[SYS]: system\n[ME]: user\n[AI]: assistant\n[ME]: user"))
      (cui-block-msgs--collect-chat-messages-from-string test-string "system"))
    '((:role system :content "system")
      (:role user :content "user")
      (:role assistant :content "assistant")
      (:role user :content "user"))))

  ;; (should
  ;;  (equal
  ;;   (let ((test-string "[SYS]: system\n[ME]: user\n[AI]: assistant\n[ME]: user"))
  ;;     (cui-block-msgs--collect-chat-messages-from-string test-string nil "pers-system1" nil " "))
  ;;   '[(:role system :content "system")
  ;;     (:role user :content "pers-system1 user")
  ;;     (:role assistant :content "assistant")
  ;;     (:role user :content "pers-system1 user")]))

  ;; (should
  ;;  (equal
  ;;   (let ((test-string "[SYS]: system\n[ME]: user\n[AI]: assistant\n[ME]: user"))
  ;;     (cui-block-msgs--collect-chat-messages-from-string test-string "def-system1" nil "maxt-system2" " "))
  ;;   '[(:role system :content "system maxt-system2")
  ;;     (:role user :content "user")
  ;;     (:role assistant :content "assistant")
  ;;     (:role user :content "user")]))

  ;; merge messages with same role

    (let ((test-string "[ME]: hello\n[ME]: world")
          res)
      (setq res (cui-block-msgs--collect-chat-messages-from-string test-string))
      (should (equal res '((:role user :content "hello") (:role user :content "world"))))
      (setq res (vconcat (cui-block-msgs--merge-by-role res)))
      (should (equal res '[(:role user :content "hello\nworld")])))

  (should
   (equal
    (let ((test-string "[ME:] hello world")) (cui-block-msgs--collect-chat-messages-from-string test-string))
    '((:role user :content "hello world")))))



;; -=-= Test: `cui-block-msgs--stringify-chat-messages'
(ert-deftest cui-tests-block-msgs--stringify-chat-messages1()
  (let ((cui-block-roles-prefixes '(("SYS" . system)
                                   ("ME" . user)
                                   ("AI" . assistant)
                                   ("AI_REASON" . assistant_reason)))
        (parts
         (list
          (list :role 'user :content "Hi." )
          (list :role 'user :content "How are you?" )
          (list :role 'assistant :content "I'm fine.")
          (list :role 'user :content "Hi." )))
        res)
    (setq res (cui-block-msgs--stringify-chat-messages (apply #'vector parts)))
    (should (string-equal res
                          "[ME]: Hi.

[ME]: How are you?

[AI]: I'm fine.

[ME]: Hi."))))


(ert-deftest cui-tests-block-msgs--stringify-chat-messages2 ()
  (let ((cui-block-roles-prefixes '(("SYS1" . system)
                           ("ME2" . user)
                           ("AI3" . assistant)))
        res)
    (setq res (cui-block-msgs--stringify-chat-messages '[(:role system :content "system")
                                            (:role user :content "user")
                                            (:role assistant :content "assistant")]))
  (should
   (string-equal res "[SYS1]: system\n\n[ME2]: user\n\n[AI3]: assistant"))
  (setq res (cui-block-msgs--stringify-chat-messages '[(:role user :content "user")
                                                  (:role assistant :content "assistant")]
                                                "system1"))
  (should
   (string-equal res "[SYS1]: system1\n\n[ME2]: user\n\n[AI3]: assistant"))))



;; -=-= For `cui-block-msgs--vector-split-by-chat-prefix'
(ert-deftest cui-tests-restapi--vector-split-by-chat-prefix ()
  (let ((v1 [(:role 'user :content "foo\n[me:]bar")
             (:role 'assistant :content "baz")
             (:role 'user :content "qux\n[ai:]\nquux")
             (:role 'user :content "\ncorge")])
        (idxs '(0 2))
        res)
    (setq res (cui-block-msgs--vector-split-by-chat-prefix v1 idxs))
    (should (equal res
                   '((:role 'user :content "foo") (:role user :content "bar")
                     (:role 'assistant :content "baz")
                     (:role 'user :content "qux") (:role assistant :content "quux")
                     (:role 'user :content "\ncorge")))))

  ;; (setq res (cui-block-msgs--vector-split-by-chat-prefix v1 idxs))
  ;; (setq idxs '(2 0))
  ;; (setq res (cui-block-msgs--vector-split-by-chat-prefix v1 idxs))
  ;; (when (not (equal res
  ;;                   ["foo\n" "[me:]bar" "baz" "qux\n" "[ai:]\nquux" "\ncorge"]))
;;     (error "Test:cui-block-msgs--vector-split-by-chat-prefix1"))
;;   (setq idxs '(0 1))
;;   (setq res (cui-block-msgs--vector-split-by-chat-prefix v1 idxs))
;;   (when (not (equal res
;;                     ["foo\n" "[me:]bar" "baz" "qux\n[ai:]\nquux" "\ncorge"]))
;;              (error "Test:cui-block-msgs--vector-split-by-chat-prefix2")))

  (should (equal
   (cui-block-msgs--vector-split-by-chat-prefix '[(:role system :content "ad")
                                               (:role user :content "adb\n[ai:] bb")] '(1))
   '((:role system :content "ad") (:role user :content "adb") (:role assistant :content "bb"))))

  (should (equal
           (cui-block-msgs--vector-split-by-chat-prefix '[(:role system :content "ad")
                                                       (:role assistant :content "adb\n[ai:] bb")] '(1))
           '((:role system :content "ad") (:role assistant :content "adb") (:role assistant :content "bb")))))


;; -=-= For: `cui-block-msgs--modify-vector-content'
(ert-deftest cui-tests-block-msgs--modify-vector-content1 ()
  (should
   (equal (cui-block-msgs--modify-vector-content
           '[(:role system :content "foo")
             (:role user :content "How to make coffe1?")
             (:role assistant :content "IDK.")
             (:role user :content "How to make coffe2?")
             (:role system :content "other")]
           (lambda (x) (concat x " w11"))
           'user)
          '[(:role system :content "foo")
            (:role user :content "How to make coffe1? w11")
            (:role assistant :content "IDK.")
            (:role user :content "How to make coffe2? w11")
            (:role system :content "other")])))

(ert-deftest cui-tests-block-msgs--modify-vector-content2 ()
  (should
   (equal (cui-block-msgs--modify-vector-content
           '[(:role system :content "foo")
             (:role user :content "How to make coffe1?")
             (:role assistant :content "IDK.")
             (:role user :content "How to make coffe2?")
             (:role system :content "other")]
           (lambda (x) (concat x " w11")))
          '[(:role system :content "foo w11")
            (:role user :content "How to make coffe1? w11")
            (:role assistant :content "IDK. w11")
            (:role user :content "How to make coffe2? w11")
            (:role system :content "other w11")])))

(ert-deftest cui-tests-block-msgs--modify-vector-content3 ()
  (should (equal
           (cui-block-msgs--modify-vector-content
            '[(:role system :content "Think.") (:role user :content ((:type "text" :text "What is on image?") (:type "image_url" :image_url (:url "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAABQY"))))]
            #'cui-block-tags--clear-properties)
           '[(:role system :content "Think.") (:role user :content ((:type "text" :text "What is on image?") (:type "image_url" :image_url (:url "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAABQY"))))])))

;; -=-= For: `cui-block-msgs--modify-vector-last-user-content'
(ert-deftest cui-tests-msgs--modify-last-user-content ()
  (should
   (equal (cui-block-msgs--modify-vector-last-user-content
           ;; vec
           (vector (list :role 'system :content "foo")
                   (list :role 'user :content "How to make coffe1?")
                   (list :role 'assistant :content "IDK.")
                   (list :role 'user :content "How to make coffe2?")
                   (list :role 'system :content "other"))
           ;; applicant
           (lambda (x) (concat x " w11")))
          '[(:role system :content "foo")
            (:role user :content "How to make coffe1?")
            (:role assistant :content "IDK.")
            (:role user :content "How to make coffe2? w11")
            (:role system :content "other")]))
  (let (res)
    (setq res (cui-block-msgs--modify-vector-last-user-content '[(:role system :content "ad") (:role user :content "ad\n[ai:] Asd")] (lambda (x) x) ))
    (should (equal res '[(:role system :content "ad") (:role user :content "ad\n[ai:] Asd")])))
  (let (res)
    (setq res (cui-block-msgs--modify-vector-last-user-content '[(:role system :content "ad") (:role user :content "vvb") (:role user :content "ad\n[ai:] Asd")]
                                                            (lambda (x) (concat x "b"))
                                                            t ; split
                                                            ))
    (should (equal res '[(:role system :content "ad") (:role user :content "vvb\nad") (:role assistant :content "Asdb")])))

  (let (res)
    (setq res (cui-block-msgs--modify-vector-last-user-content '[(:role system :content "ad") (:role user :content "vvb") (:role user :content "ad\n[ai:] Asd")]
                                                            (lambda (x) (concat x "b"))
                                                            nil ; split
                                                            ))
    (should (equal res '[(:role system :content "ad") (:role user :content "vvb") (:role user :content "ad\n[ai:] Asdb")]))))



(provide 'cui-tests-restapi)






;;; cui-tests-msgs.el ends here
