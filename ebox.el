;; ebox.el --- Draw styled rectangles in Emacs -*- lexical-binding: t -*-

;; Copyright (C) 2024 Laluxx
;; Author: Laluxx
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1"))
;; Keywords: frames, tools
;; URL: https://github.com/laluxx/ebox

;;; Commentary:
;; A package for drawing styled rectangles in Emacs using child frames.
;; This allows for pixel-precise positioning and styling of rectangular elements.
;; TODO use `popon-0.13'

;;; Code:

(defgroup ebox nil
  "Draw styled rectangles in Emacs."
  :group 'frames)

(defcustom ebox-default-style
  '((background-color . "#333333")
    (border-color . "#666666")
    (border-width . 1)
    (opacity . 90))
  "Default style for ebox rectangles."
  :type '(alist :key-type symbol :value-type sexp)
  :group 'ebox)

(defvar-local ebox--frame-list nil
  "List of active ebox frames in the current buffer.")

(defun ebox--create-face (style)
  "Create a new face for the ebox with STYLE."
  (let ((face-name (make-symbol "ebox-face")))
    (face-spec-set face-name
                   `((t :background ,(alist-get 'background-color style "#333333")
                        :foreground ,(alist-get 'foreground-color style "#FFFFFF")
                        :extend t)))
    face-name))

(defun ebox--setup-buffer (buffer style)
  "Set up BUFFER with STYLE for ebox content."
  (with-current-buffer buffer
    ;; Create and apply a face that overrides theme
    (let ((face (ebox--create-face style)))
      (face-remap-add-relative 'default face)
      ;; Fill buffer with spaces to ensure full coloring
      (erase-buffer)
      (insert (make-string 200 ?\s))  ; Adjust number based on max expected size
      ;; Ensure our face stays active
      (font-lock-mode -1)
      (buffer-disable-undo)
      ;; Prevent any user interaction
      (read-only-mode 1))))

(defun ebox-create (x y width height &optional style)
  "Create a styled rectangle at X,Y with WIDTH and HEIGHT.
Optional STYLE is an alist of frame parameters."
  (let* ((merged-style (or style ebox-default-style))
         (buffer (generate-new-buffer " *ebox*"))
         ;; Convert pixel dimensions to character units
         (char-width (/ width (frame-char-width)))
         (char-height (/ height (frame-char-height)))
         (frame-params
          `((left . ,x)
            (top . ,y)
            (width . ,char-width)
            (height . ,char-height)
            (minibuffer . nil)
            (vertical-scroll-bars . nil)
            (horizontal-scroll-bars . nil)
            (menu-bar-lines . 0)
            (tool-bar-lines . 0)
            (tab-bar-lines . 0)
            (internal-border-width . ,(alist-get 'border-width merged-style 1))
            (internal-border-color . ,(alist-get 'border-color merged-style "#666666"))
            (alpha . ,(alist-get 'opacity merged-style 90))
            (parent-frame . ,(selected-frame))
            (keep-ratio . t)
            (undecorated . t)
            (no-accept-focus . t)
            (no-focus-on-map . t)
            (override-redirect . t)
            (z-group . above)
            (visibility . t)
            ;; Override theme background
            (background-color . ,(alist-get 'background-color merged-style "#333333"))
            (face-remap-add-relative . ((default (:background ,(alist-get 'background-color merged-style "#333333")))))))
         (frame (make-frame frame-params)))
    
    ;; Set up the buffer with persistent styling
    (ebox--setup-buffer buffer merged-style)
    
    ;; Switch to our styled buffer in the frame
    (with-selected-frame frame
      (switch-to-buffer buffer)
      (setq mode-line-format nil
            header-line-format nil
            cursor-type nil))
    
    ;; Track the frame
    (push frame ebox--frame-list)
    
    ;; Return the frame
    frame))

(defun ebox-update (frame &rest properties)
  "Update FRAME with new PROPERTIES.
PROPERTIES is a plist of frame parameters to update."
  (when (frame-live-p frame)
    (modify-frame-parameters frame properties)))

(defun ebox-move (frame x y)
  "Move FRAME to new position X,Y."
  (ebox-update frame `(left . ,x) `(top . ,y)))

(defun ebox-resize (frame width height)
  "Resize FRAME to WIDTH and HEIGHT."
  (ebox-update frame 
               `(width . ,(/ width (frame-char-width)))
               `(height . ,(/ height (frame-char-height)))))

(defun ebox-set-style (frame style)
  "Apply STYLE properties to FRAME."
  (when (frame-live-p frame)
    ;; Update frame parameters
    (ebox-update frame
                 `(internal-border-width . ,(alist-get 'border-width style 1))
                 `(internal-border-color . ,(alist-get 'border-color style "#666666"))
                 `(background-color . ,(alist-get 'background-color style "#333333"))
                 `(alpha . ,(alist-get 'opacity style 90)))
    
    ;; Update buffer face
    (when-let ((buffer (frame-parameter frame 'buffer)))
      (ebox--setup-buffer buffer style))))

(defun ebox-delete (frame)
  "Delete the ebox FRAME."
  (when (frame-live-p frame)
    (delete-frame frame)
    (setq ebox--frame-list (delq frame ebox--frame-list))))

(defun ebox-delete-all ()
  "Delete all ebox frames in the current buffer."
  (dolist (frame ebox--frame-list)
    (when (frame-live-p frame)
      (delete-frame frame)))
  (setq ebox--frame-list nil))

;; Example styles
(defvar ebox-style-transparent
  '((background-color . "#FFFFFF")
    (border-color . "#000000")
    (border-width . 1)
    (opacity . 50))
  "A transparent style for ebox.")

(defvar ebox-style-solid
  '((background-color . "#000000")
    (border-color . "#FFFFFF")
    (border-width . 2)
    (opacity . 100))
  "A solid style for ebox.")

(provide 'ebox)
;;; ebox.el ends here
