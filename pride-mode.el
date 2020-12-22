;;; pride-mode.el --- Pride flag shows position in current buffer in mode-line -*- lexical-binding: t; -*-

;; Copyright (C) 2020 halfwhole

;; Author: halfwhole
;; Version: 0.1
;; Package-Requires: ((emacs "24.1"))
;; URL: https://github.com/halfwhole/pride-mode/

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Pride flag shows position in current buffer in mode-line.
;; Adapted from nyan-mode, written by Jacek "TeMPOraL" Zlydach.
;; See: https://github.com/TeMPOraL/nyan-mode

;;; Code:

(defconst pride-directory (file-name-directory (or load-file-name buffer-file-name)))
(defconst pride-rainbow-image (concat pride-directory "img/rainbow.xpm"))
(defconst pride-outerspace-image (concat pride-directory "img/outerspace.xpm"))
(defconst pride-modeline-help-string "Pride mode\nmouse-1: Scroll buffer position")

(defvar pride-old-car-mode-line-position nil)

(defgroup pride nil
  "Customization group for `pride-mode'."
  :group 'frames)

(defcustom pride-minimum-window-width 64
  "Minimum width of the window, below which the pride bar will not be displayed.
This is important because the bar can push out information from small windows."
  :type 'integer
  :group 'pride)

(defcustom pride-bar-length 64
  "Length of the entire bar in units.
Each unit is equal to a 4px-wide image."
  :type 'integer
  :group 'pride)

(defun pride--number-of-rainbows ()
  "Return the number of rainbows to be used in the bar."
  (let* ((curr-pos (float (point)))
	 (begin-pos (float (point-min)))
	 (end-pos (float (point-max)))
	 (fraction (/ (- curr-pos begin-pos) end-pos)))
    (round (* fraction pride-bar-length))))

(defun pride--scroll-buffer (percentage buffer)
  "Move point `BUFFER' to `PERCENTAGE' percent in the buffer."
  (with-current-buffer buffer
    (goto-char (floor (* percentage (point-max))))))

(defun pride--add-scroll-handler (string percentage buffer)
  "Propertize `STRING' to scroll `BUFFER' to `PERCENTAGE' on click."
  (propertize string 'keymap `(keymap (mode-line keymap (down-mouse-1 . ,(lambda () (interactive) (pride--scroll-buffer percentage buffer)))))))

(defun pride--create-string-unit (default-string image)
  "Create a string unit using `IMAGE' if possible, otherwise default to `DEFAULT-STRING'."
  (if (image-type-available-p 'xpm)
      (propertize default-string 'display (create-image image 'xpm nil :ascent 'center))
    default-string))

(defun pride-create ()
  "Create the pride flag to be inserted into the mode-line."
  (if (< (window-width) pride-minimum-window-width)
      ""                                 ; Disable for windows that are too small
    (let* ((num-rainbows (pride--number-of-rainbows))
           (num-outerspaces (- pride-bar-length num-rainbows))
           (rainbow-string "")
           (outerspace-string "")
           (buffer (current-buffer)))
      (unless (display-images-p)         ; Shorten bar for text-only display
	  (setq num-rainbows (/ num-rainbows 2))
	  (setq num-outerspaces (- (/ pride-bar-length 2) num-rainbows)))
      (dotimes (number num-rainbows)
        (setq rainbow-string (concat rainbow-string
                                     (pride--add-scroll-handler
				      (pride--create-string-unit "≡" pride-rainbow-image)
                                      (/ (float number) pride-bar-length) buffer))))
      (dotimes (number num-outerspaces)
        (setq outerspace-string (concat outerspace-string
                                        (pride--add-scroll-handler
					 (pride--create-string-unit "-" pride-outerspace-image)
                                         (/ (float (+ num-rainbows number)) pride-bar-length) buffer))))
      (propertize (concat rainbow-string outerspace-string) 'help-echo pride-modeline-help-string))))

;;;###autoload
(define-minor-mode pride-mode
  "Use the pride flag to show your position in the current buffer in the mode-line.
You can customize this minor mode; see option `pride-mode'."
  :global t
  :group 'pride
  (if (not pride-mode)
      (setcar mode-line-position pride-old-car-mode-line-position)
    (unless pride-old-car-mode-line-position
      (setq pride-old-car-mode-line-position (car mode-line-position)))
    (setcar mode-line-position '(:eval (list (pride-create))))))

(provide 'pride-mode)

;;; pride-mode.el ends here
