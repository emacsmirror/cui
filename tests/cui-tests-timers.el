;;; cui-tests-timers.el --- AI blocks for org-mode. -*- lexical-binding: t; -*-

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

;; (eval-buffer) or (load-file "path/to/async-tests.el")
;; Running Tests: Load the test file and run:
;; (eval-buffer)
;; (ert t)

;;; Code:

(require 'ert)             ; Testing framework
(require 'cui-timers)

;;; -=-= 1)

(ert-deftest cui-tests-timers--get-keys-for-variable ()
  "Should return current buffer as key for the marker present, only once (seq-uniq)."
  (let* ((marker (make-marker))
         (cb (current-buffer))
         ;; Only the first pair with cb will be considered for alist-get
         (cui-timers--element-marker-variable-dict `((,cb . ,marker)
                                                     (,cb . ,(make-marker))
                                                     (,cb . ,marker))))
    (let ((result (cui-timers--get-keys-for-variable marker)))
      ;; Result should just be a list containing cb, thanks to seq-uniq
      (should (equal result (list cb)))
      (should (= (length result) 1)))))


(ert-deftest cui-tests-timers--get-keys-for-variable-none ()
  "Should return nil when marker not present in the dict."
  (let* ((query-marker (make-marker))
         (cb (current-buffer))
         (marker1 (make-marker))
         (marker2 (make-marker)))
    (set-marker marker1 1)
    (set-marker marker2 2)
    (let ((cui-timers--element-marker-variable-dict `((,cb . ,marker1)
                                                     (,cb . ,marker2))))
      ;; query-marker is unpositioned, so not equal to marker1 or marker2
      (should (equal (cui-timers--get-keys-for-variable query-marker) nil)))))

(ert-deftest cui-tests-timers--get-keys-for-variable-none-symbol ()
  "Should return nil when symbol not present in the dict."
  (let* ((cb (current-buffer))
         (cui-timers--element-marker-variable-dict `((,cb . alpha)
                                                     (,cb . beta))))
    (should (equal (cui-timers--get-keys-for-variable 'gamma) nil))))

(ert-deftest cui-tests-timers--set-and-get-keys-for-variable ()
  "Testing set, get, and keys-for-variable."
  (let ((marker (make-marker))
        (cb (current-buffer))
        (cui-timers--element-marker-variable-dict nil))
    ;; Set mapping
    (cui-timers--set cb marker)
    (let ((result (cui-timers--get-keys-for-variable marker)))
      (should (equal result (list cb)))
      (should (= (length result) 1)))))

;;; -=-= 2)

(ert-deftest cui-tests-timers--set-and-get-variable1 ()
  "Test setting and getting variables by key."
  (let ((cui-timers--element-marker-variable-dict nil))
    (cui-timers--set 1 'foo)
    (should (equal (cui-timers--get-variable 1) 'foo))
    ;; Overwrite value
    (cui-timers--set 1 'bar)
    (should (equal (cui-timers--get-variable 1) 'bar))
    ;; Setting to nil removes the key
    (cui-timers--set 1 nil)
    (should-not (cui-timers--get-variable 1))))

(ert-deftest cui-tests-timers--set-and-get-variable1-real ()
  (let ((cui-timers--element-marker-variable-dict nil)
        (buffer (current-buffer))
        (marker1 (copy-marker (point))))
    (with-temp-buffer
      (let ((tem-buf (current-buffer))
            (marker2 (copy-marker (point))))

        (should (equal (cui-timers--get-variable buffer) nil))

        (cui-timers--set buffer marker1)
        (cui-timers--set tem-buf marker1)

        (should (equal (cui-timers--get-variable buffer) marker1))
        (should (equal (cui-timers--get-variable tem-buf) marker1))
        (cui-timers--set tem-buf marker2)
        (should (equal (cui-timers--get-variable tem-buf) marker2))))))

(ert-deftest cui-tests-timers--get-keys-for-variable2 ()
  "Test retrieval of all keys mapped to a variable."
  (let ((cui-timers--element-marker-variable-dict nil))
    (cui-timers--set 'a 100)
    (cui-timers--set 'b 200)
    (cui-timers--set 'c 100)
    ;; Both 'a and 'c map to 100, 'b to 200
    (should (equal (sort (cui-timers--get-keys-for-variable 100) #'string<) '(a c)))
    (should (equal (cui-timers--get-keys-for-variable 200) '(b)))
    ;; Not present
    (should (equal (cui-timers--get-keys-for-variable 300) nil))))

(ert-deftest cui-tests-timers--remove-variable ()
  "Test removing all mappings by variable (eq)."
  (let ((cui-timers--element-marker-variable-dict nil))
    (cui-timers--set 'a 'marker1)
    (cui-timers--set 'b 'marker2)
    (cui-timers--set 'c 'marker1)
    ;; Remove marker1, leaving only marker2 mapping
    (cui-timers--remove-variable 'marker1)
    ;; (print cui-timers--element-marker-variable-dict))
    ;; (equal cui-timers--element-marker-variable-dict '((b . marker2))))
    (should (equal cui-timers--element-marker-variable-dict '((b . marker2))))
    ;; Remove marker2, dict is empty
    (cui-timers--remove-variable 'marker2)
    (should (equal cui-timers--element-marker-variable-dict nil))))

(ert-deftest cui-tests-timers--remove-variable-remove-real ()
  "Test removing all mappings by marker value."
  (let ((cui-timers--element-marker-variable-dict nil)
        (buffer (current-buffer))
        (marker1 (copy-marker (point)))
        )
    (with-temp-buffer
      (let ((tem-buf (current-buffer))
            (marker2 (copy-marker (point)))
            (marker3 (copy-marker (point)))
            )
        ;; Set
        (cui-timers--set tem-buf marker1)
        (cui-timers--set buffer marker2)
        ;; Remove marker1, leaving only marker2 mapping
        (cui-timers--remove-variable marker1)

        (should (= (length cui-timers--element-marker-variable-dict) 1))
        (should (equal (cui-timers--get-variable buffer) marker2))

        (cui-timers--remove-variable marker2)
        (should (equal cui-timers--element-marker-variable-dict nil))

        (cui-timers--set buffer marker1)
        (cui-timers--set tem-buf marker1)
        (cui-timers--remove-variable marker1)
        (should (equal cui-timers--element-marker-variable-dict nil))
        ))))

(ert-deftest cui-tests-timers--remove-key-removes-only-that-key ()
  "Test removing only the specified key."
  (let ((cui-timers--element-marker-variable-dict nil))
    (cui-timers--set 'alpha 'v1)
    (cui-timers--set 'beta 'v2)
    (cui-timers--remove-key 'beta)
    (should (equal cui-timers--element-marker-variable-dict '((alpha . v1))))
    ;; Removing non-existing key does nothing
    (cui-timers--remove-key 'gamma)
    (should (equal cui-timers--element-marker-variable-dict '((alpha . v1))))))


(ert-deftest cui-tests-timers--get-all-keys ()
  "Test getting all unique keys."
  (let ((cui-timers--element-marker-variable-dict nil))
    (cui-timers--set 10 'x)
    (cui-timers--set 20 'y)
    (cui-timers--set 30 'x)
    (should (equal (sort (cui-timers--get-all-keys) #'<) '(10 20 30)))
    ;; Remove one key
    (cui-timers--remove-key 20)
    (should (equal (sort (cui-timers--get-all-keys) #'<) '(10 30)))
    ;; Remove all
    (cui-timers--remove-key 10)
    (cui-timers--remove-key 30)
    (should (equal (cui-timers--get-all-keys) nil))))

;;; -=-= 3) special cases
(ert-deftest cui-tests-timers--buffer-key-type ()
  (let ((cui-timers--element-marker-variable-dict nil))
    (cui-timers--set (current-buffer) 'symbval)
    (should (equal (cui-timers--get-variable (current-buffer)) 'symbval))
    ;; Remove complex key
    (cui-timers--remove-key (current-buffer))
    (should-not (cui-timers--get-variable (current-buffer)))))


;; ### 3. **Test setting a key multiple times with different values**
;; Make sure only last value remains, test repeated setting.
(ert-deftest cui-tests-timers--repeated-set-override ()
  (let ((cui-timers--element-marker-variable-dict nil))
    (cui-timers--set 'x 'a)
    (cui-timers--set 'x 'b)
    (cui-timers--set 'x 'c)
    (should (equal (cui-timers--get-variable 'x) 'c))
    (should (equal (length cui-timers--element-marker-variable-dict) 1))))

;; ### 4. **Test `get-keys-for-variable` with no matches**
;; Should return `nil` or empty list.
(ert-deftest cui-tests-timers--get-keys-for-nonexistent-variable ()
  (let ((cui-timers--element-marker-variable-dict nil))
    (cui-timers--set 'a 'one)
    (should (equal (cui-timers--get-keys-for-variable 'missing) nil))))

;; ### 5. **Test with empty dictionary**
;; All retrieval functions should handle empty dict gracefully.
(ert-deftest cui-tests-timers--empty-dict-behavior ()
  (let ((cui-timers--element-marker-variable-dict nil))
    (should-not (cui-timers--get-variable 'a))
    (should (equal (cui-timers--get-keys-for-variable 'x) nil))
    (should (equal (cui-timers--get-all-keys) nil))))

;; ### 6. **Test removing key that does not exist**
;; Should be a no-op.
(ert-deftest cui-tests-timers--remove-nonexistent-key-noop ()
  (let ((cui-timers--element-marker-variable-dict nil))
    (cui-timers--set 'a 'xx)
    (cui-timers--remove-key 'nonexistent)
    (should (equal (cui-timers--get-all-keys) '(a)))))

;; ### 7. **Test that `set`ing a key to nil really removes it, not just assigns nil**
;; Ensure the pair is gone (not key with nil value).
(ert-deftest cui-tests-timers--set-key-to-nil-actually-removes ()
  (let ((cui-timers--element-marker-variable-dict nil))
    (cui-timers--set 'foo 'bar)
    (cui-timers--set 'foo nil)
    (should-not (assoc 'foo cui-timers--element-marker-variable-dict))))

;; ### 8. **Test `get-all-keys` with duplicate keys (should be unique)**
(ert-deftest cui-tests-timers--get-all-keys-uniqueness ()
  (let ((cui-timers--element-marker-variable-dict nil))
    (cui-timers--set 'dup 'a)
    (cui-timers--set 'dup 'b) ; overwrite
    (should (equal (cui-timers--get-all-keys) '(dup)))))

(provide 'cui-tests-timers)

;;; cui-tests-timers.el ends here
