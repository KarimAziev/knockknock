;;; knockknock.el --- Unobtrusive notifications with icons and SVG support -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Mikael Konradsson

;; Author: Mikael Konradsson
;; Version: 0.2.0
;; Package-Requires: ((emacs "26.1") (posframe "1.0.0") (nerd-icons "0.1.0"))
;; Keywords: convenience, notifications, alerts
;; URL: https://github.com/mikaelkonradsson/knockknock

;;; Commentary:

;; knockknock provides unobtrusive notifications for Emacs using posframe.
;; It displays temporary alert messages in a centered frame that automatically
;; disappears after a configurable duration.  Supports nerd-icons for beautiful
;; visual notifications with icons, titles, and messages.
;;
;; Two layout modes are available:
;; - Text-based (default): Uses nerd-icons with text properties
;; - SVG-based: Uses SVG for pixel-perfect positioning
;;
;; Usage:
;;   ;; Simple message (legacy API)
;;   (knockknock-alert "Hello, World!")
;;   (knockknock-alert "Custom duration" 5)
;;
;;   ;; With icon and title (new API)
;;   (knockknock-notify :title "Build Complete"
;;                      :message "All tests passed!"
;;                      :icon "nf-cod-check"
;;                      :duration 5)
;;
;;   ;; Enable SVG layout for pixel-perfect positioning
;;   (setq knockknock-use-svg-layout t)
;;
;; To manually close an alert:
;;   M-x knockknock-close

;;; Code:

(require 'posframe)
(require 'nerd-icons)

;;; Customization

(defgroup knockknock nil
  "Unobtrusive notifications for Emacs."
  :group 'convenience
  :prefix "knockknock-")

(defcustom knockknock-default-duration 3
  "Default duration in seconds for displaying alerts."
  :type 'number
  :group 'knockknock)

(defcustom knockknock-border-width 1
  "Width of the internal border of the alert frame."
  :type 'integer
  :group 'knockknock)

(defcustom knockknock-border-color nil
  "Color of the internal border of the alert frame."
  :type '(choice (const :tag "Use theme default" nil)
                 (string :tag "Custom color"))
  :group 'knockknock)

(defcustom knockknock-background-color nil
  "Background color of the alert frame.
If nil, uses the default background color from your theme."
  :type '(choice (const :tag "Use theme default" nil)
                 (string :tag "Custom color"))
  :group 'knockknock)

(defcustom knockknock-foreground-color nil
  "Foreground (text) color of the alert frame.
If nil, uses the default foreground color from your theme."
  :type '(choice (const :tag "Use theme default" nil)
                 (string :tag "Custom color"))
  :group 'knockknock)

(defcustom knockknock-left-fringe 8
  "Left fringe width of the alert frame."
  :type 'integer
  :group 'knockknock)

(defcustom knockknock-right-fringe 8
  "Right fringe width of the alert frame."
  :type 'integer
  :group 'knockknock)

(defcustom knockknock-poshandler #'posframe-poshandler-window-bottom-right-corner
  "Position handler function for the alert frame.
See `posframe-show' for available handlers."
  :type 'function
  :group 'knockknock)

(defcustom knockknock-icon-size 2.0
  "Size multiplier for the icon."
  :type 'number
  :group 'knockknock)

(defcustom knockknock-icon-padding 2
  "Number of spaces between icon and text."
  :type 'integer
  :group 'knockknock)

(defcustom knockknock-text-column 4
  "Column position for title and message text (after icon).
Increase this value if text overlaps with icon, decrease to bring text closer."
  :type 'integer
  :group 'knockknock)

(defcustom knockknock-default-icon "nf-fa-info_circle"
  "Default nerd-icon to use when none is specified."
  :type 'string
  :group 'knockknock)

(defcustom knockknock-use-icons t
  "Whether to display icons in notifications."
  :type 'boolean
  :group 'knockknock)

(defcustom knockknock-use-svg-layout t
  "Use SVG-based layout for pixel-perfect positioning.
When non-nil (default), uses SVG for rendering notifications with exact positioning.
When nil, uses text-based layout with nerd-icons."
  :type 'boolean
  :group 'knockknock)

(defcustom knockknock-max-image-size 10000
  "Maximum image size for SVG rendering.
This is set automatically when knockknock loads to allow SVG notifications.
Set to nil to use Emacs default max-image-size."
  :type '(choice (const :tag "Use Emacs default" nil)
                 (integer :tag "Custom size"))
  :group 'knockknock)

(defcustom knockknock-svg-icon-size 32
  "Icon size in pixels when using SVG layout."
  :type 'integer
  :group 'knockknock)

(defcustom knockknock-svg-width 300
  "Width of SVG canvas in pixels."
  :type 'integer
  :group 'knockknock)

(defcustom knockknock-svg-padding 12
  "Padding between icon and text in pixels for SVG layout."
  :type 'integer
  :group 'knockknock)

(defcustom knockknock-max-message-width 40
  "Maximum number of characters per line for message text.
Messages longer than this will be wrapped to multiple lines."
  :type 'integer
  :group 'knockknock)

;;; Faces

(defface knockknock-title-face
  '((t :weight bold :height 1.3))
  "Face for notification titles."
  :group 'knockknock)

(defface knockknock-message-face
  '((t :inherit default :height 1.0))
  "Face for notification messages."
  :group 'knockknock)

(defface knockknock-icon-face
  '((t :inherit default))
  "Face for notification icons."
  :group 'knockknock)

;;; Internal variables

(defvar knockknock--buffer "*knockknock*"
  "Buffer name for posframe alerts.")

(defvar knockknock--timer nil
  "Timer for auto-hiding the alert.")

;;; Functions

(defun knockknock--wrap-text (text max-width)
  "Wrap TEXT into lines of maximum MAX-WIDTH characters.
Returns a list of strings, each representing one line."
  (if (or (not text) (<= (length text) max-width))
      (list text)
    (let ((words (split-string text))
          (lines '())
          (current-line ""))
      (dolist (word words)
        (let ((test-line (if (string-empty-p current-line)
                            word
                          (concat current-line " " word))))
          (if (<= (length test-line) max-width)
              (setq current-line test-line)
            (when (not (string-empty-p current-line))
              (push current-line lines))
            (setq current-line word))))
      (when (not (string-empty-p current-line))
        (push current-line lines))
      (nreverse lines))))

;;;###autoload
(defun knockknock-debug-svg ()
  "Debug function to test SVG rendering in a buffer.
Opens a buffer showing how the SVG notification would look."
  (interactive)
  (let ((buf (get-buffer-create "*knockknock-debug*")))
    (with-current-buffer buf
      (erase-buffer)
      (knockknock--format-buffer-svg "Test Title" "Test message here" "cod-check")
      (goto-char (point-min)))
    (switch-to-buffer buf)))

(defun knockknock--get-icon (icon-name)
  "Get the icon string for ICON-NAME.
ICON-NAME can be in format \"nf-cod-check\" or \"cod-check\".
Returns the icon string or nil if not found."
  (when (and knockknock-use-icons icon-name)
    (let* ((parts (split-string icon-name "-"))
           (family (if (string= (car parts) "nf")
                       (cadr parts)
                     (car parts)))
           (name (if (string= (car parts) "nf")
                     (string-join (cddr parts) "-")
                   (string-join (cdr parts) "-"))))
      (condition-case nil
          (pcase family
            ("cod" (nerd-icons-codicon (concat "nf-cod-" name)))
            ("fa" (nerd-icons-faicon (concat "nf-fa-" name)))
            ("oct" (nerd-icons-octicon (concat "nf-oct-" name)))
            ("dev" (nerd-icons-devicon (concat "nf-dev-" name)))
            ("md" (nerd-icons-mdicon (concat "nf-md-" name)))
            ("fl" (nerd-icons-flicon (concat "nf-fl-" name)))
            ("pom" (nerd-icons-pomicon (concat "nf-pom-" name)))
            ("suc" (nerd-icons-sucicon (concat "nf-suc-" name)))
            ("wi" (nerd-icons-wicon (concat "nf-weather-" name)))
            (_ (nerd-icons-codicon (concat "nf-cod-" icon-name))))
        (error nil)))))

(defun knockknock--format-buffer-svg (title message icon)
  "Format the notification buffer using SVG for pixel-perfect layout.
ICON is on left, TITLE and MESSAGE on right with exact positioning."
  (require 'svg)
  (require 'dom)
  (let* ((icon-str (knockknock--get-icon icon))
         (icon-size knockknock-svg-icon-size)
         (padding knockknock-svg-padding)
         (canvas-width knockknock-svg-width)
         ;; Calculate heights and positions - keep small to avoid max-image-size
         (title-font-size 16)
         (message-font-size 12)
         (line-spacing 4)
         (margin 8)
         (icon-x margin)
         (icon-y (+ icon-size margin))  ; Baseline for icon
         ;; Text position: if no icon, start at margin, otherwise after icon
         (text-x (if icon-str
                     (+ icon-size padding margin)
                   margin))
         (title-y (+ margin icon-size -12))  ; Position title near top
         (message-y (+ title-y title-font-size line-spacing))
         ;; Wrap message text and calculate height
         (message-lines (when message (knockknock--wrap-text message knockknock-max-message-width)))
         (num-message-lines (length message-lines))
         (message-block-height (* num-message-lines (+ message-font-size line-spacing)))
         ;; Calculate total height with extra bottom padding
         (bottom-padding 4)
         (total-height (+ icon-size (* 2 margin) bottom-padding message-block-height))
         ;; Colors from faces - use theme defaults
         (default-fg (or (face-foreground 'default nil t) "#ffffff"))
         (title-color (or (face-foreground 'knockknock-title-face nil t) default-fg))
         (message-color (or (face-foreground 'knockknock-message-face nil t) default-fg))
         (icon-color (or (face-foreground 'knockknock-icon-face nil t) default-fg)))

    ;; Create SVG
    (let ((svg (svg-create canvas-width total-height)))

      ;; Add icon - use nerd-icons compatible font
      (when icon-str
        (let* ((nerd-font "Symbols Nerd Font Mono")
               (text-node (dom-node 'text
                                   `((x . ,icon-x)
                                     (y . ,icon-y)
                                     (font-size . ,icon-size)
                                     (font-family . ,nerd-font)
                                     (fill . ,icon-color)))))
          (dom-append-child text-node icon-str)
          (svg--append svg text-node)))

      ;; Add title using DOM nodes
      (when title
        (let ((text-node (dom-node 'text
                                   `((x . ,text-x)
                                     (y . ,title-y)
                                     (font-size . ,title-font-size)
                                     (font-weight . "bold")
                                     (fill . ,title-color)))))
          (dom-append-child text-node title)
          (svg--append svg text-node)))

      ;; Add message using DOM nodes - multiple lines if needed
      (when message-lines
        (let ((current-y message-y))
          (dolist (line message-lines)
            (let ((text-node (dom-node 'text
                                       `((x . ,text-x)
                                         (y . ,current-y)
                                         (font-size . ,message-font-size)
                                         (fill . ,message-color)))))
              (dom-append-child text-node line)
              (svg--append svg text-node))
            ;; Move to next line
            (setq current-y (+ current-y message-font-size line-spacing)))))

      ;; Insert the SVG as an image
      (insert-image (svg-image svg)))))

(defun knockknock--format-buffer (title message icon)
  "Format the notification buffer with ICON on left, TITLE and MESSAGE on right.
Uses SVG layout if `knockknock-use-svg-layout' is non-nil, otherwise text layout."
  (erase-buffer)

  (if knockknock-use-svg-layout
      ;; SVG-based layout for pixel-perfect positioning
      (knockknock--format-buffer-svg title message icon)

    ;; Text-based layout with nerd-icons
    (let* ((icon-str (knockknock--get-icon icon))
           (padding (make-string knockknock-icon-padding ?\s)))

      (if icon-str
          ;; Layout with icon
          (let* ((text-column knockknock-text-column))
            ;; Create the icon with increased size
            (insert (propertize icon-str
                                'face 'knockknock-icon-face
                                'display `(height ,knockknock-icon-size)))
            (insert padding)

            ;; Insert title on same line
            (when title
              (insert (propertize title 'face 'knockknock-title-face)))

            ;; Insert message on new line, aligned with title - wrap if needed
            (when message
              (let ((message-lines (knockknock--wrap-text message knockknock-max-message-width)))
                (dolist (line message-lines)
                  (insert "\n")
                  ;; Align to the text column position
                  (insert (propertize " " 'display `(space :align-to ,text-column)))
                  (insert (propertize line 'face 'knockknock-message-face))))))

        ;; Layout without icon - just text
        (when title
          (insert (propertize title 'face 'knockknock-title-face)))
        (when message
          (let ((message-lines (knockknock--wrap-text message knockknock-max-message-width)))
            (dolist (line message-lines)
              (insert "\n")
              (insert (propertize line 'face 'knockknock-message-face)))))))))

;;;###autoload
(defun knockknock-notify (&rest args)
  "Display a notification with optional ICON, TITLE, and MESSAGE.

ARGS is a property list with the following keys:
  :title    - Title text (optional)
  :message  - Message text (optional)
  :icon     - Nerd-icon name (optional, defaults to `knockknock-default-icon')
  :duration - Duration in seconds (optional, defaults to `knockknock-default-duration')

Examples:
  (knockknock-notify :title \"Success\" :message \"Build completed\")
  (knockknock-notify :title \"Error\"
                     :message \"Build failed\"
                     :icon \"nf-cod-error\"
                     :duration 5)"
  (interactive)
  (let* ((title (plist-get args :title))
         (message (plist-get args :message))
         (icon (or (plist-get args :icon) knockknock-default-icon))
         (duration (or (plist-get args :duration) knockknock-default-duration)))

    ;; Cancel any existing timer
    (when knockknock--timer
      (cancel-timer knockknock--timer)
      (setq knockknock--timer nil))

    ;; Create or clear the buffer and format it
    (with-current-buffer (get-buffer-create knockknock--buffer)
      (knockknock--format-buffer title message icon))

    ;; Display posframe with optional color parameters
    (apply #'posframe-show
           knockknock--buffer
           :poshandler knockknock-poshandler
           :internal-border-width knockknock-border-width
           :internal-border-color knockknock-border-color
           :left-fringe knockknock-left-fringe
           :right-fringe knockknock-right-fringe
           ;; Only pass color parameters if they are non-nil
           (append
            (when knockknock-background-color
              (list :background-color knockknock-background-color))
            (when knockknock-foreground-color
              (list :foreground-color knockknock-foreground-color))))

    ;; Hide after specified duration
    (setq knockknock--timer
          (run-with-timer duration nil #'knockknock-close))))

;;;###autoload
(defun knockknock-alert (message &optional duration)
  "Display an alert MESSAGE in a posframe for DURATION seconds.
If DURATION is nil, use `knockknock-default-duration'."
  (interactive "sMessage: ")
  (let ((duration (or duration knockknock-default-duration)))
    ;; Cancel any existing timer
    (when knockknock--timer
      (cancel-timer knockknock--timer)
      (setq knockknock--timer nil))

    ;; Create or clear the buffer
    (with-current-buffer (get-buffer-create knockknock--buffer)
      (erase-buffer)
      (insert message))

    ;; Display posframe with optional color parameters
    (apply #'posframe-show
           knockknock--buffer
           :poshandler knockknock-poshandler
           :internal-border-width knockknock-border-width
           :internal-border-color knockknock-border-color
           :left-fringe knockknock-left-fringe
           :right-fringe knockknock-right-fringe
           ;; Only pass color parameters if they are non-nil
           (append
            (when knockknock-background-color
              (list :background-color knockknock-background-color))
            (when knockknock-foreground-color
              (list :foreground-color knockknock-foreground-color))))

    ;; Hide after specified duration
    (setq knockknock--timer
          (run-with-timer duration nil #'knockknock-close))))

;;;###autoload
(defun knockknock-close ()
  "Manually close the alert posframe."
  (interactive)
  (when knockknock--timer
    (cancel-timer knockknock--timer)
    (setq knockknock--timer nil))
  (posframe-hide knockknock--buffer)
  (posframe-delete knockknock--buffer))

;;; Setup

;; Set max-image-size for SVG rendering
(when knockknock-max-image-size
  (setq max-image-size knockknock-max-image-size))

(provide 'knockknock)

;;; knockknock.el ends here
