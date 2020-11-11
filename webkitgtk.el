;;; webkitgtk.el --- webkitgtk dynamic module -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Akira Kyle

;; Author: Akira Kyle <ak@akirakyle.com>
;; URL: https://github.com/
;; Version: 0.1
;; Package-Requires: ((emacs "28.1"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3, or (at your
;; option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; webkitgtk dynamic module

;;; Code:

;; Don't require dynamic module at byte compile time.
(declare-function webkitgtk--new "webkitgtk-module")
(declare-function webkitgtk--destroy "webkitgtk-module")
(declare-function webkitgtk--resize "webkitgtk-module")
(declare-function webkitgtk--hide "webkitgtk-module")
(declare-function webkitgtk--show "webkitgtk-module")
(declare-function webkitgtk--focus "webkitgtk-module")
(declare-function webkitgtk--unfocus "webkitgtk-module")
(declare-function webkitgtk--forward "webkitgtk-module")
(declare-function webkitgtk--back "webkitgtk-module")
(declare-function webkitgtk--reload "webkitgtk-module")
(declare-function webkitgtk--get-zoom "webkitgtk-module")
(declare-function webkitgtk--set-zoom "webkitgtk-module")
(declare-function webkitgtk--get-title "webkitgtk-module")
(declare-function webkitgtk--get-uri "webkitgtk-module")
(declare-function webkitgtk--load-uri "webkitgtk-module")
(declare-function webkitgtk--execute-js "webkitgtk-module")
(declare-function webkitgtk--add-user-style "webkitgtk-module")
(declare-function webkitgtk--remove-all-user-styles "webkitgtk-module")
(declare-function webkitgtk--add-user-script "webkitgtk-module")
(declare-function webkitgtk--remove-all-user-scripts "webkitgtk-module")
(declare-function webkitgtk--register-script-message "webkitgtk-module")
(declare-function webkitgtk--unregister-script-message "webkitgtk-module")

(require 'webkitgtk-module)

(defconst webkitgtk-base (file-name-directory load-file-name))

(defgroup webkitgtk nil
  "webkitgtk browser ."
  :group 'convenience)

(defcustom webkitgtk-search-prefix "https://duckduckgo.com/html/?q="
  "Prefix URL to search engine."
  :group 'webkitgtk
  :type 'string)

(defcustom webkitgtk-own-window nil
  "Whether webkitgtk should use its own window instead of
attemptting to embed itself in its buffer. The curretly focused
frame must be display-graphic-p and either x or pgtk when
webkitgtk-new is run in order for embedding to work."
  :group 'webkitgtk
  :type 'boolean)

(defvar webkitgtk-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "g" 'webkitgtk)
    (define-key map "f" 'webkitgtk-forward)
    (define-key map "b" 'webkitgtk-back)
    (define-key map "r" 'webkitgtk-reload)
    (define-key map "i" 'webkitgtk-insert-mode)
    (define-key map "+" 'webkitgtk-zoom-in)
    (define-key map "-" 'webkitgtk-zoom-out)

    ;;similar to image mode bindings
    (define-key map (kbd "SPC")                 'webkitgtk-scroll-up)
    (define-key map (kbd "S-SPC")               'webkitgtk-scroll-down)
    (define-key map (kbd "DEL")                 'webkitgtk-scroll-down)

    (define-key map [remap scroll-up]           'webkitgtk-scroll-up-line)
    (define-key map [remap scroll-up-command]   'webkitgtk-scroll-up)

    (define-key map [remap scroll-down]         'webkitgtk-scroll-down-line)
    (define-key map [remap scroll-down-command] 'webkitgtk-scroll-down)

    (define-key map [remap forward-char]        'webkitgtk-scroll-forward)
    (define-key map [remap backward-char]       'webkitgtk-scroll-backward)
    (define-key map [remap right-char]          'webkitgtk-scroll-forward)
    (define-key map [remap left-char]           'webkitgtk-scroll-backward)
    (define-key map [remap previous-line]       'webkitgtk-scroll-down-line)
    (define-key map [remap next-line]           'webkitgtk-scroll-up-line)

    (define-key map [remap beginning-of-buffer] 'webkitgtk-scroll-top)
    (define-key map [remap end-of-buffer]       'webkitgtk-scroll-bottom)
    map)
  "Keymap for `webkitgtk-mode'.")

(defun webkitgtk-zoom-in (&optional webkitgtk-id)
  "Increase webkitgtk view zoom factor."
  (interactive)
  (webkitgtk--set-zoom
   (or webkitgtk-id webkitgtk--id)
   (+ (webkitgtk--get-zoom
       (or webkitgtk-id webkitgtk--id))
      0.1)))

(defun webkitgtk-zoom-out (&optional webkitgtk-id)
  "Decrease webkitgtk view zoom factor."
  (interactive)
  (webkitgtk--set-zoom
   (or webkitgtk-id webkitgtk--id)
   (+ (webkitgtk--get-zoom
       (or webkitgtk-id webkitgtk--id))
      -0.1)))

(defun webkitgtk-scroll-up (&optional arg webkitgtk-id)
  "Scroll webkitgtk up by ARG pixels; or full window height if no ARG.
Stop if bottom of page is reached.
Interactively, ARG is the prefix numeric argument.
Negative ARG scrolls down."
  (interactive "P")
  (webkitgtk--execute-js
   (or webkitgtk-id webkitgtk--id)
   (format "window.scrollBy(0, %d);"
           (or arg (pcase-let ((`(,left ,top ,right ,bottom)
                                (window-inside-pixel-edges (selected-window))))
                    (- bottom top))))))

(defun webkitgtk-scroll-down (&optional arg webkitgtk-id)
  "Scroll webkitgtk down by ARG pixels; or full window height if no ARG.
Stop if top of page is reached.
Interactively, ARG is the prefix numeric argument.
Negative ARG scrolls up."
  (interactive "P")
  (webkitgtk--execute-js
   (or webkitgtk-id webkitgtk--id)
   (format "window.scrollBy(0, -%d);"
           (or arg (pcase-let ((`(,left ,top ,right ,bottom)
                                (window-inside-pixel-edges (selected-window))))
                     (- bottom top))))))

(defun webkitgtk-scroll-up-line (&optional n webkitgtk-id)
  "Scroll webkitgtk up by N lines.
The height of line is calculated with `window-font-height'.
Stop if the bottom edge of the page is reached.
If N is omitted or nil, scroll up by one line."
  (interactive "p")
  (webkitgtk-scroll-up (* n (window-font-height))))

(defun webkitgtk-scroll-down-line (&optional n webkitgtk-id)
  "Scroll webkitgtk down by N lines.
The height of line is calculated with `window-font-height'.
Stop if the top edge of the page is reached.
If N is omitted or nil, scroll down by one line."
  (interactive "p")
  (webkitgtk-scroll-down (* n (window-font-height))))

(defun webkitgtk-scroll-forward (&optional n webkitgtk-id)
  "Scroll webkitgtk horizontally by N chars.
The width of char is calculated with `window-font-width'.
If N is omitted or nil, scroll forwards by one char."
  (interactive "p")
  (webkitgtk--execute-js
   (or webkitgtk-id webkitgtk--id)
   (format "window.scrollBy(%d, 0);"
           (* n (window-font-width)))))

(defun webkitgtk-scroll-backward (&optional n webkitgtk-id)
  "Scroll webkitgtk back by N chars.
The width of char is calculated with `window-font-width'.
If N is omitted or nil, scroll backwards by one char."
  (interactive "p")
  (webkitgtk--execute-js
   (or webkitgtk-id webkitgtk--id)
   (format "window.scrollBy(-%d, 0);"
           (* n (window-font-width)))))

(defun webkitgtk-scroll-top (&optional webkitgtk-id)
  "Scroll webkitgtk to the very top."
  (interactive)
  (webkitgtk--execute-js
   (or webkitgtk-id webkitgtk--id)
   "window.scrollTo(pageXOffset, 0);"))

(defun webkitgtk-scroll-bottom (&optional webkitgtk-id)
  "Scroll webkitgtk to the very bottom."
  (interactive)
  (webkitgtk--execute-js
   (or webkitgtk-id webkitgtk--id)
   "window.scrollTo(pageXOffset, window.document.body.scrollHeight);"))

(defun webkitgtk-forward (&optional webkitgtk-id)
  "Go forward in history."
  (interactive)
  (webkitgtk--forward (or webkitgtk-id webkitgtk--id)))

(defun webkitgtk-back (&optional webkitgtk-id)
  "Go back in history."
  (interactive)
  (webkitgtk--back (or webkitgtk-id webkitgtk--id)))

(defun webkitgtk-reload (&optional webkitgtk-id)
  "Reload current URL."
  (interactive)
  (webkitgtk--reload (or webkitgtk-id webkitgtk--id)))

(defun webkitgtk-insert-mode (&optional webkitgtk-id)
  (interactive)
  (webkitgtk--focus (or webkitgtk-id webkitgtk--id)))

(defun webkitgtk-ace-toggle-callback (msg)
  (message msg))

(defun webkitgtk-ace (&optional webkitgtk-id)
  "Start a webkitgtk ace jump."
  (interactive)
  (webkitgtk--execute-js
   (or webkitgtk-id webkitgtk--id)
   "webkitHints();" "webkitgtk-ace-toggle-callback"))

(defun webkitgtk--file-to-string (filename)
  (with-temp-buffer
    (insert-file-contents filename)
    (buffer-string)))

(defun webkitgtk--callback-key-down (val)
  (message val)
  (webkitgtk--unfocus webkitgtk--id))

(defun webkitgtk--callback-title (title)
  (if (string= "" title)
      (let ((uri (webkitgtk--get-uri webkitgtk--id)))
        (if (string= "" uri)
            (rename-buffer "*webkitgtk*" t)
          (rename-buffer uri t)))
    (rename-buffer title t)))

(defun webkitgtk--callback-uri (uri)
  (unless (string= "" uri)
    (message uri)
    ))

(defun webkitgtk--callback-progress (progress)
  (message "%s%%" progress))

(defun webkitgtk--callback-new-view (uri)
  (webkitgtk-new uri))

(defun webkitgtk--callback-download-request (uri)
  (message "TODO: download request for %s" uri))

(defun webkitgtk--close (msg)
  (set-process-query-on-exit-flag (get-buffer-process (current-buffer)) nil)
  (kill-this-buffer))

(defun webkitgtk--filter (proc string)
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (goto-char (point-max))
      (insert string)
      (goto-char 1)
      (while (re-search-forward "\\([^\x00]*\\)\x00\\([^\x00]*\\)\x00" nil t)
        (let ((id (match-string 1))
              (msg (match-string 2)))
          (delete-region 1 (match-end 0))
          (message "id: %s; message: %s" id msg)
          (funcall (intern id) msg))))))

(defun webkitgtk--adjust-size (frame)
  "Adjust webkitgtk size for window in FRAME"
  ;;(message "adjusting size...")
  (dolist (buffer webkitgtk--buffers)
    (if (buffer-live-p buffer)
        (with-current-buffer buffer
          (let* ((windows (get-buffer-window-list (current-buffer) 'nomini frame)))
            (if (not windows)
                (webkitgtk--hide webkitgtk--id)
              (pcase-let ((`(,left ,top ,right ,bottom)
                           (window-inside-pixel-edges (car windows))))
                (webkitgtk--show webkitgtk--id)
                (webkitgtk--resize webkitgtk--id
                                   left top (- right left) (- bottom top)))
              (dolist (window (cdr windows))
                (switch-to-prev-buffer window))))))))

(defun webkitgtk--kill-buffer ()
  (when (eq major-mode 'webkitgtk-mode)
    ;;(webkitgtk--hide webkitgtk--id)
    (webkitgtk--destroy webkitgtk--id)
    (setq webkitgtk--buffers (delq (current-buffer) webkitgtk--buffers))))

(setq webkitgtk--script (webkitgtk--file-to-string
                         (expand-file-name "script.js" webkitgtk-base)))
(setq webkitgtk--style (webkitgtk--file-to-string
                        (expand-file-name "style.css" webkitgtk-base)))

(defun webkitgtk-new (&optional url buffer-name noquery)
  "Create a new webkitgtk with URL

If called with an argument BUFFER-NAME, the name of the new buffer will
be set to BUFFER-NAME, otherwise it will be `webkitgtk'.
Returns the newly created webkitgtk buffer"
  (let ((buffer (generate-new-buffer (or buffer-name "*webkitgtk*"))))
    (with-current-buffer buffer
      (webkitgtk-mode)
      (setq webkitgtk--id (webkitgtk--new
                           (make-pipe-process :name "webkitgtk"
                                              :buffer buffer
                                              :filter 'webkitgtk--filter
                                              :noquery noquery)
                           webkitgtk-own-window))
      (push buffer webkitgtk--buffers)
      (webkitgtk--register-script-message
       webkitgtk--id "webkitgtk--callback-key-down")
      (webkitgtk--add-user-script webkitgtk--id webkitgtk--script)
      (webkitgtk--add-user-style webkitgtk--id webkitgtk--style)
      (when url (webkitgtk--load-uri webkitgtk--id url))
      (when (fboundp 'posframe-delete-all)
        (posframe-delete-all)) ;; hack necessary to get correct z-ordering
      (switch-to-buffer buffer))))

(require 'browse-url)

(defun webkitgtk-browse-url (url &optional new-session)
  "Goto URL with webkitgtk using browse-url.

NEW-SESSION specifies whether to create a new webkitgtk session or use the 
current session."
  (interactive (progn (browse-url-interactive-arg "URL: ")))
  (if (or new-session (not webkitgtk--buffers))
      (webkitgtk-new url)
    (webkitgtk--load-uri (or webkitgtk--id
                             (with-current-buffer (car webkitgtk--buffers)
                               webkitgtk--id))
                         url)))

(defun webkitgtk (url &optional arg)
  "Fetch URL and render the page.
If the input doesn't look like an URL or a domain name, the
word(s) will be searched for via `webkitgtk-search-prefix'.

If called with a prefix ARG, create a new webkit buffer instead of reusing
the default webkit buffer."
  (interactive
   (let ((prompt "URL or keywords: "))
     (list ;;(if (require 'webkitgtk-history nil t)
           ;;    (webkitgtk-history-completing-read prompt "")
             (read-string prompt nil 'eww-prompt-history "")
           (prefix-numeric-value current-prefix-arg))))
  (let ((eww-search-prefix webkitgtk-search-prefix))
    (webkitgtk-browse-url (eww--dwim-expand-url url) (eq arg 4))))

(define-derived-mode webkitgtk-mode special-mode "webkitgtk"
  "webkitgtk view mode."
  (setq buffer-read-only nil))

(make-variable-buffer-local 'webkitgtk--id)
(setq webkitgtk--buffers nil)

(unless webkitgtk-own-window
  (add-hook 'window-size-change-functions #'webkitgtk--adjust-size))
;;(remove-hook 'window-size-change-functions #'webkitgtk--adjust-size)

(add-hook 'kill-buffer-hook #'webkitgtk--kill-buffer)

(provide 'webkitgtk)
;;; webkitgtk.el ends here
