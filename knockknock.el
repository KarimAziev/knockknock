;;; knockknock.el --- Unobtrusive notifications with icons and SVG support -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Mikael Konradsson

;; Author: Mikael Konradsson
;; Version: 0.2.9
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

(require 'cl-lib)
(require 'posframe)
(require 'nerd-icons)
(require 'svg)

(defvar knockknock--log-file "/tmp/.knockknock.log"
  "File used for I/O operations that stabilize Emacs.
This file is truncated at startup to prevent unbounded growth.")

(defun knockknock--log (format-string &rest args)
  "Stabilize Emacs by performing a small I/O operation.
This prevents race condition crashes during startup.
The actual logging is a side effect - the I/O itself is what matters."
  (ignore-errors
    (let ((inhibit-message t))
      (append-to-file (concat (apply #'format format-string args) "\n")
                      nil knockknock--log-file))))

;; Truncate log file at load time to prevent unbounded growth
(ignore-errors
  (when (file-exists-p knockknock--log-file)
    (write-region "" nil knockknock--log-file nil 'silent)))

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

(defcustom knockknock-darken-background-percent 0
  "Percentage to darken the background color (0-100).
If 0, uses the theme's background color unchanged.
Positive values darken the background (e.g., 5 makes it 5% darker)."
  :type 'integer
  :group 'knockknock)

(defcustom knockknock-lighten-background-percent 0
  "Percentage to lighten the background color (0-100).
If 0, uses the theme's background color unchanged.
Positive values lighten the background (e.g., 5 makes it 5% lighter).
Note: If both darken and lighten are set, darken takes precedence."
  :type 'integer
  :group 'knockknock)

(defcustom knockknock-left-fringe 10
  "Left fringe width of the alert frame."
  :type 'integer
  :group 'knockknock)

(defcustom knockknock-right-fringe 10
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

(defcustom knockknock-debug nil
  "Enable debug logging for knockknock.
When non-nil, prints debug messages to *Messages* buffer."
  :type 'boolean
  :group 'knockknock)

(defcustom knockknock-use-svg-layout t
  "Use SVG-based layout for pixel-perfect positioning.
When non-nil (default), uses SVG for rendering notifications with exact positioning.
When nil, uses text-based layout with nerd-icons.
Includes XML escaping and error handling to prevent crashes."
  :type 'boolean
  :group 'knockknock)

(defcustom knockknock-svg-icon-size 32
  "Icon size in pixels when using SVG layout."
  :type 'integer
  :group 'knockknock)

(defcustom knockknock-svg-min-width 300
  "Minimum width of SVG canvas in pixels."
  :type 'integer
  :group 'knockknock)

(defcustom knockknock-svg-max-width 500
  "Maximum width of SVG canvas in pixels."
  :type 'integer
  :group 'knockknock)

(defcustom knockknock-svg-padding 12
  "Padding between icon and text in pixels for SVG layout."
  :type 'integer
  :group 'knockknock)

(defcustom knockknock-left-padding 12
  "Left padding in pixels from the leading edge to the icon."
  :type 'integer
  :group 'knockknock)

(defcustom knockknock-right-padding 16
  "Right padding in pixels from the text to the trailing edge."
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

(defvar knockknock--svg-cache (make-hash-table :test 'equal)
  "Cache for generated SVG images.
Keys are lists of (title message icon), values are the SVG image objects.")

(defvar knockknock--max-cache-size 50
  "Maximum number of SVG images to keep in cache.")

(defvar knockknock--initialized nil
  "Non-nil if knockknock has been initialized.")

(defvar knockknock--frame-ready nil
  "Non-nil when the graphical frame is ready for SVG rendering.
This prevents crashes from SVG/image rendering during early startup
before the display system is fully initialized.")

(defvar knockknock--pending-notifications nil
  "Queue of notifications waiting for frame to be ready.
Each element is a plist of notification arguments.")

(defvar knockknock--debounce-timer nil
  "Timer for debouncing rapid notifications.")

(defvar knockknock--debounce-delay 0.15
  "Delay in seconds before showing a notification.
This prevents crashes from rapid successive notifications.")

(defun knockknock--show-debounced-notification ()
  "Show the most recent debounced notification."
  (knockknock--log "Showing debounced notification")
  (setq knockknock--debounce-timer nil)
  (when knockknock--pending-notifications
    (let ((args (car knockknock--pending-notifications)))
      (setq knockknock--pending-notifications nil)
      (when args
        (knockknock--log "Calling notify-internal for debounced")
        (apply #'knockknock--notify-internal args)
        (knockknock--log "Debounced notify-internal returned")))))

(defun knockknock--frame-ready-p ()
  "Return non-nil if the frame is ready for SVG rendering.
Checks that we have a graphical display and the frame is visible."
  (and (display-graphic-p)
       (frame-live-p (selected-frame))
       (frame-visible-p (selected-frame))
       ;; Check that image support is available
       (image-type-available-p 'svg)
       ;; Ensure we're past initial frame setup
       knockknock--frame-ready))

;;; Functions

(defvar knockknock--original-svg-setting nil
  "Stores the original `knockknock-use-svg-layout' value during startup.")

(defun knockknock--warmup-posframe ()
  "Warm up posframe by showing a minimal text-only frame.
This initializes internal posframe state to prevent crashes on first real use.
SVG is explicitly disabled during warmup to avoid image-related crashes."
  (when knockknock-debug
    (message "knockknock: Warming up posframe (SVG disabled)..."))
  ;; Temporarily force text mode during warmup
  (let ((knockknock-use-svg-layout nil))
    (condition-case err
        (progn
          ;; Create buffer with minimal text content (no SVG)
          (with-current-buffer (get-buffer-create knockknock--buffer)
            (let ((inhibit-read-only t))
              (erase-buffer)
              (insert "Initializing...")))
          ;; Show posframe briefly to initialize internals
          (posframe-show knockknock--buffer
                         :string "."
                         :timeout 0.05
                         :poshandler #'posframe-poshandler-frame-bottom-right-corner
                         :background-color (face-background 'default nil t)
                         :foreground-color (face-foreground 'default nil t))
          ;; Hide it after a short delay
          (run-with-timer 0.1 nil
                          (lambda ()
                            (ignore-errors
                              (posframe-hide knockknock--buffer)
                              (posframe-delete knockknock--buffer))))
          (when knockknock-debug
            (message "knockknock: Posframe warmup complete")))
      (error
       (when knockknock-debug
         (message "knockknock: Posframe warmup failed: %s" err))))))

(defun knockknock--process-pending-notifications ()
  "Process any pending notifications that were queued during startup."
  (when knockknock--pending-notifications
    (when knockknock-debug
      (message "knockknock: Processing %d pending notifications"
               (length knockknock--pending-notifications)))
    ;; Show only the last notification to avoid spam
    (let ((last-notification (car (last knockknock--pending-notifications))))
      (setq knockknock--pending-notifications nil)
      (when last-notification
        (apply #'knockknock--notify-internal last-notification)))))

(defun knockknock--mark-frame-ready ()
  "Mark the frame as ready for rendering.
This is called after Emacs startup is complete."
  (knockknock--log "--mark-frame-ready called")
  ;; First warm up posframe to prevent crashes
  (knockknock--warmup-posframe)
  ;; Then mark as ready after warmup has had time to complete
  (run-with-timer 0.1 nil
                  (lambda ()
                    (knockknock--log "Setting frame-ready=t after warmup")
                    (setq knockknock--frame-ready t)
                    ;; Process any pending notifications
                    (run-with-timer 0.1 nil #'knockknock--process-pending-notifications))))

(defun knockknock--check-frame-ready ()
  "Check if frame is truly ready for posframe/SVG rendering.
Returns t if all conditions are met for safe rendering."
  (and (display-graphic-p)
       (frame-live-p (selected-frame))
       (frame-visible-p (selected-frame))
       ;; Check that we're past initial startup
       after-init-time
       ;; Check image support
       (image-type-available-p 'svg)
       ;; Additional safety: ensure frame has been fully realized
       (frame-parameter nil 'window-id)))

(defun knockknock--ensure-initialized ()
  "Ensure knockknock is properly initialized before use.
This creates the buffer and sets up frame-ready detection to prevent crashes
when multiple notifications are shown rapidly at startup."
  (knockknock--log "--ensure-initialized called, initialized=%s, after-init-time=%s"
                   knockknock--initialized after-init-time)
  (unless knockknock--initialized
    ;; Create the buffer if it doesn't exist
    (unless (get-buffer knockknock--buffer)
      (knockknock--log "Creating buffer")
      (with-current-buffer (get-buffer-create knockknock--buffer)
        (setq-local buffer-read-only nil)
        (erase-buffer)))

    ;; Set up frame-ready detection
    (cond
     ;; Still in early init - use window-setup-hook
     ((not after-init-time)
      (knockknock--log "Still in init, adding window-setup-hook")
      (add-hook 'window-setup-hook #'knockknock--mark-frame-ready))

     ;; Past init and frame looks ready - but still wait a moment
     ((knockknock--check-frame-ready)
      (knockknock--log "Past init, frame looks ready, scheduling mark-frame-ready")
      (run-with-timer 0.2 nil #'knockknock--mark-frame-ready))

     ;; Frame not ready yet - keep checking
     (t
      (knockknock--log "Frame not ready, will retry")
      (run-with-timer 0.5 nil
                      (lambda ()
                        (knockknock--log "Retry check")
                        (if (knockknock--check-frame-ready)
                            (knockknock--mark-frame-ready)
                          ;; Still not ready, try again
                          (run-with-timer 0.5 nil #'knockknock--mark-frame-ready))))))

    (setq knockknock--initialized t)
    (knockknock--log "Initialized complete (frame-ready=%s)" knockknock--frame-ready)))

;;;###autoload
(defun knockknock-init ()
  "Initialize knockknock for use.
Call this early in your Emacs startup to prevent crashes when
multiple notifications are shown rapidly before the first manual notification.
This is automatically called by `knockknock-notify' if needed, but calling
it explicitly during startup ensures smoother operation."
  (interactive)
  (knockknock--log "knockknock-init called, after-init-time=%s, frame-ready=%s"
                   after-init-time knockknock--frame-ready)
  (knockknock--ensure-initialized)
  ;; If we're already past init and frame looks ready, do warmup now
  (when (and after-init-time
             (display-graphic-p)
             (frame-live-p (selected-frame))
             (not knockknock--frame-ready))
    (knockknock--log "Running warmup from init")
    ;; Run warmup immediately and synchronously
    (knockknock--warmup-posframe)
    ;; Small delay then mark ready
    (run-with-timer 0.2 nil #'knockknock--finalize-init)))

(defun knockknock--finalize-init ()
  "Finalize initialization after warmup is complete."
  (knockknock--log "--finalize-init called")
  (setq knockknock--frame-ready t)
  (knockknock--log "frame-ready now t, processing pending")
  (knockknock--process-pending-notifications))

(defun knockknock--color-to-rgb (color)
  "Convert COLOR (hex or name) to RGB components (0-255)."
  (let ((rgb (color-values color)))
    (if rgb
        (mapcar (lambda (x) (/ x 256)) rgb)
      (error "Invalid color: %s" color))))

(defun knockknock--rgb-to-hex (r g b)
  "Convert R G B components to hex color string."
  (format "#%02x%02x%02x" r g b))

(defun knockknock--darken-color (color percent)
  "Darken COLOR by PERCENT (0-100)."
  (let* ((rgb (knockknock--color-to-rgb color))
         (darkened (mapcar (lambda (component)
                             (max 0
                                  (min 255
                                       (floor (* component (- 100 percent) 0.01)))))
                           rgb)))
    (apply #'knockknock--rgb-to-hex darkened)))

(defun knockknock--lighten-color (color percent)
  "Lighten COLOR by PERCENT (0-100)."
  (let* ((rgb (knockknock--color-to-rgb color))
         (lightened (mapcar (lambda (component)
                              (max 0
                                   (min 255
                                        (floor (+ component
                                                  (* (- 255 component)
                                                     (/ percent 100.0)))))))
                            rgb)))
    (apply #'knockknock--rgb-to-hex lightened)))

(defun knockknock--adjust-background-color (color)
  "Adjust COLOR based on darken/lighten settings.
Returns the adjusted color or COLOR if no adjustment is needed."
  (cond
   ((> knockknock-darken-background-percent 0)
    (knockknock--darken-color color knockknock-darken-background-percent))
   ((> knockknock-lighten-background-percent 0)
    (knockknock--lighten-color color knockknock-lighten-background-percent))
   (t color)))

(defun knockknock--xml-escape (text)
  "Escape TEXT for safe inclusion in XML/SVG.
Returns nil if TEXT is nil."
  (when text
    (let ((result text))
      (setq result (replace-regexp-in-string "&" "&amp;" result))
      (setq result (replace-regexp-in-string "<" "&lt;" result))
      (setq result (replace-regexp-in-string ">" "&gt;" result))
      (setq result (replace-regexp-in-string "\"" "&quot;" result))
      (setq result (replace-regexp-in-string "'" "&apos;" result))
      result)))

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

(defun knockknock--load-svg-file (file-path)
  "Load SVG content from FILE-PATH.
Returns the SVG data as a string, or nil if the file cannot be read.
FILE-PATH is expanded to handle ~ and other path shortcuts."
  (when file-path
    (let ((expanded-path (expand-file-name file-path)))
      (condition-case err
          (when (file-readable-p expanded-path)
            (with-temp-buffer
              (insert-file-contents expanded-path)
              (buffer-string)))
        (error
         (when knockknock-debug
           (message "knockknock: Failed to load SVG file %s: %s" expanded-path err))
         nil)))))

(defun knockknock--cache-key (title message icon &optional icon-file)
  "Generate cache key from TITLE, MESSAGE, ICON, and optional ICON-FILE."
  (list (or title "") (or message "") (or icon "") (or icon-file "")))

(defun knockknock--get-cached-svg (title message icon &optional icon-file)
  "Get cached SVG image for TITLE, MESSAGE, ICON, and ICON-FILE, or nil if not cached."
  (gethash (knockknock--cache-key title message icon icon-file) knockknock--svg-cache))

(defun knockknock--cache-svg (title message icon image &optional icon-file)
  "Cache SVG IMAGE for TITLE, MESSAGE, ICON, and optional ICON-FILE.
If cache is full, clear oldest entries."
  (when (>= (hash-table-count knockknock--svg-cache) knockknock--max-cache-size)
    ;; Clear half the cache when full (simple LRU approximation)
    (clrhash knockknock--svg-cache))
  (puthash (knockknock--cache-key title message icon icon-file) image knockknock--svg-cache))

(defun knockknock--format-buffer-svg (title message icon &optional icon-file)
  "Format the notification buffer using SVG for pixel-perfect layout.
ICON is on left, TITLE and MESSAGE on right with exact positioning.
If ICON-FILE is provided, embed the custom SVG file instead of using nerd-icons."
  (require 'svg)
  (require 'dom)
  ;; Set reasonable max-image-size for notifications
  (let ((max-image-size 8000))
    (let* ((custom-svg-data (knockknock--load-svg-file icon-file))
           (icon-str (and (not custom-svg-data)
                          icon
                          (knockknock--xml-escape (knockknock--get-icon icon))))
           (has-icon (or custom-svg-data icon-str))
           (title (knockknock--xml-escape title))
           (message (knockknock--xml-escape message))
         (icon-size knockknock-svg-icon-size)
         (padding knockknock-svg-padding)
         ;; Calculate heights and positions - keep small to avoid max-image-size
         (title-font-size 16)
         (message-font-size 12)
         (line-spacing 4)
         (margin knockknock-left-padding)
         (right-margin knockknock-right-padding)
         (icon-x margin)
         (icon-y (+ icon-size margin))  ; Baseline for icon
         ;; Text position: if no icon, start at margin, otherwise after icon
         (text-x (if has-icon
                     (+ icon-size padding margin)
                   margin))
         (title-y (+ margin icon-size -12))  ; Position title near top
         (message-y (+ title-y title-font-size line-spacing))
         ;; Calculate needed width based on text content
         ;; Estimate: ~7 pixels per character for 12px font, ~8 for 16px bold title
         (title-width (if title (* (length title) 8) 0))
         (message-width (if message (* (length message) 7) 0))
         (needed-width (+ text-x (max title-width message-width) right-margin))
         ;; Constrain canvas width between min and max
         (canvas-width (max knockknock-svg-min-width
                           (min knockknock-svg-max-width needed-width)))
         ;; Calculate available text width and characters per line
         (available-text-width (- canvas-width text-x right-margin))
         (chars-per-line (max 20 (/ available-text-width 7)))
         ;; Wrap message text and calculate height
         (message-lines (when message (knockknock--wrap-text message chars-per-line)))
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

      ;; Add icon - either custom SVG file or nerd-icons font
      (cond
       ;; Custom SVG file
       (custom-svg-data
        (let ((data-uri (concat "data:image/svg+xml;base64,"
                                (base64-encode-string custom-svg-data t))))
          (svg--append svg
                       (dom-node 'image
                                 `((x . ,icon-x)
                                   (y . ,margin)
                                   (width . ,icon-size)
                                   (height . ,icon-size)
                                   (xlink:href . ,data-uri))))))
       ;; Nerd-icons font icon
       (icon-str
        (let* ((nerd-font "Symbols Nerd Font Mono")
               (text-node (dom-node 'text
                                   `((x . ,icon-x)
                                     (y . ,icon-y)
                                     (font-size . ,icon-size)
                                     (font-family . ,nerd-font)
                                     (fill . ,icon-color)))))
          (dom-append-child text-node icon-str)
          (svg--append svg text-node))))

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

      ;; Convert to image and cache it
      (let ((img (svg-image svg)))
        (when knockknock-debug
          (message "knockknock: SVG created, size: %dx%d, image: %s"
                   canvas-width total-height (if img "OK" "FAILED")))
        ;; Cache the generated image
        (knockknock--cache-svg title message icon img icon-file)
        (insert-image img))))))

(defun knockknock--format-buffer-text (title message icon &optional _icon-file)
  "Format the notification buffer using text-based layout with nerd-icons.
ICON is on left, TITLE and MESSAGE on right.
ICON-FILE is ignored in text mode (SVG embedding not possible)."
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
            (insert (propertize line 'face 'knockknock-message-face))))))))

(defun knockknock--format-buffer (title message icon &optional icon-file)
  "Format the notification buffer with ICON on left, TITLE and MESSAGE on right.
Uses SVG layout if `knockknock-use-svg-layout' is non-nil and the frame is ready,
otherwise falls back to text layout to prevent crashes during startup.
If ICON-FILE is provided, use the custom SVG file (only works in SVG layout mode)."
  (erase-buffer)

  ;; Determine if we can safely use SVG layout
  (let ((use-svg (and knockknock-use-svg-layout
                      (knockknock--frame-ready-p))))
    (when knockknock-debug
      (message "knockknock: Formatting with svg=%s (requested=%s, frame-ready=%s) title=%s message=%s icon=%s icon-file=%s"
               use-svg knockknock-use-svg-layout (knockknock--frame-ready-p)
               title message icon icon-file))
    (if use-svg
        ;; SVG-based layout for pixel-perfect positioning with error handling
        (condition-case err
            (progn
              ;; Check cache first
              (let ((cached-img (knockknock--get-cached-svg title message icon icon-file)))
                (if cached-img
                    (progn
                      (when knockknock-debug
                        (message "knockknock: Using cached SVG"))
                      (insert-image cached-img))
                  ;; Not in cache, generate new SVG
                  (when knockknock-debug
                    (message "knockknock: Generating new SVG..."))
                  (knockknock--format-buffer-svg title message icon icon-file)
                  (when knockknock-debug
                    (message "knockknock: SVG rendering complete")))))
          (error
           ;; Fall back to text layout if SVG fails
           (message "knockknock: SVG rendering failed (%s), falling back to text layout" err)
           (erase-buffer)
           (knockknock--format-buffer-text title message icon)))
      ;; Text-based layout (either by config or because frame isn't ready)
      (when knockknock-debug
        (message "knockknock: Using text layout%s"
                 (if (and knockknock-use-svg-layout (not (knockknock--frame-ready-p)))
                     " (frame not ready for SVG)"
                   "")))
      (knockknock--format-buffer-text title message icon))))

(defun knockknock--notify-internal (&rest args)
  "Internal function to display a notification.
ARGS is a property list with :title, :message, :icon, :icon-file, :duration.
This should only be called when the frame is ready for rendering."
  (knockknock--log "--notify-internal called")
  (let* ((title (plist-get args :title))
         (message (plist-get args :message))
         (icon (or (plist-get args :icon) knockknock-default-icon))
         (icon-file (plist-get args :icon-file))
         (duration (or (plist-get args :duration) knockknock-default-duration)))

    (knockknock--log "title=%s icon=%s" title icon)

    ;; Cancel any existing timer
    (when knockknock--timer
      (cancel-timer knockknock--timer)
      (setq knockknock--timer nil))

    (knockknock--log "about to format buffer")
    ;; Create or clear the buffer and format it with error handling
    (condition-case err
        (with-current-buffer (get-buffer-create knockknock--buffer)
          (let ((inhibit-read-only t))
            (knockknock--format-buffer title message icon icon-file)))
      (error
       (knockknock--log "Error formatting: %s" err)
       (message "knockknock: Error formatting notification: %s" err)
       (with-current-buffer (get-buffer-create knockknock--buffer)
         (let ((inhibit-read-only t))
           (erase-buffer)
           (insert (or title "Notification"))
           (when message
             (insert "\n" message))))))

    (knockknock--log "buffer formatted, about to show posframe")
    ;; Save and temporarily increase max-image-size for SVG rendering
    (let* ((old-max-image-size max-image-size)
           ;; Get colors at display time to ensure theme colors are used
           (base-bg-color (or knockknock-background-color
                             (face-background 'default nil t)))
           ;; Apply darken/lighten adjustments
           (bg-color (knockknock--adjust-background-color base-bg-color))
           (fg-color (or knockknock-foreground-color
                        (face-foreground 'default nil t))))
      (setq max-image-size 8000)  ; Set reasonable limit for notification SVGs
      (unwind-protect
          ;; Display posframe with color parameters from current theme
          (condition-case err
              (progn
                (knockknock--log "calling posframe-show")
                (posframe-show
                 knockknock--buffer
                 :poshandler knockknock-poshandler
                 :internal-border-width knockknock-border-width
                 :internal-border-color knockknock-border-color
                 :left-fringe knockknock-left-fringe
                 :right-fringe knockknock-right-fringe
                 :background-color bg-color
                 :foreground-color fg-color)
                (knockknock--log "posframe-show returned"))
            (error
             (knockknock--log "posframe-show error: %s" err)
             (message "knockknock: Error showing posframe: %s" err)))
        ;; Always restore the original max-image-size value
        (setq max-image-size old-max-image-size)))

    (knockknock--log "setting timer")
    ;; Hide after specified duration
    (setq knockknock--timer
          (run-with-timer duration nil #'knockknock-close))
    (knockknock--log "--notify-internal done")))

;;;###autoload
(defun knockknock-notify (&rest args)
  "Display a notification with optional ICON, TITLE, and MESSAGE.

ARGS is a property list with the following keys:
  :title     - Title text (optional)
  :message   - Message text (optional)
  :icon      - Nerd-icon name (optional, defaults to `knockknock-default-icon')
  :icon-file - Path to a custom SVG file to use as icon (optional)
               Takes precedence over :icon when provided.
               Only works in SVG layout mode (`knockknock-use-svg-layout').
  :duration  - Duration in seconds (optional, defaults to `knockknock-default-duration')

During Emacs startup, notifications are queued and shown after the frame is ready.
This prevents crashes from rendering before the display system is initialized.

Examples:
  (knockknock-notify :title \"Success\" :message \"Build completed\")
  (knockknock-notify :title \"Error\"
                     :message \"Build failed\"
                     :icon \"nf-cod-error\"
                     :duration 5)
  (knockknock-notify :title \"Custom Icon\"
                     :message \"Using my own SVG!\"
                     :icon-file \"~/icons/my-icon.svg\")"
  (interactive)
  (knockknock--log "knockknock-notify called with title=%s, frame-ready=%s"
                   (plist-get args :title) knockknock--frame-ready)

  ;; Ensure knockknock is initialized
  (knockknock--ensure-initialized)

  ;; Safety check: if we're very early in startup, just queue silently
  (unless (and (display-graphic-p)
               (frame-live-p (selected-frame))
               after-init-time)
    (knockknock--log "Too early (no display/frame/after-init), queuing")
    (push args knockknock--pending-notifications)
    (cl-return-from knockknock-notify nil))

  ;; Check if frame is ready for rendering
  (if knockknock--frame-ready
      (progn
        (knockknock--log "Frame ready, debouncing notification")
        ;; Cancel any pending debounce timer
        (when knockknock--debounce-timer
          (cancel-timer knockknock--debounce-timer))
        ;; Store this notification and show after delay
        (setq knockknock--pending-notifications (list args))
        (setq knockknock--debounce-timer
              (run-with-timer knockknock--debounce-delay nil
                              #'knockknock--show-debounced-notification)))
    ;; Frame not ready - queue the notification
    (knockknock--log "Frame NOT ready, queuing notification")
    (push args knockknock--pending-notifications)))

(defun knockknock--alert-internal (message duration)
  "Internal function to display an alert MESSAGE for DURATION seconds.
This should only be called when the frame is ready for rendering."
  ;; Cancel any existing timer
  (when knockknock--timer
    (cancel-timer knockknock--timer)
    (setq knockknock--timer nil))

  ;; Create or clear the buffer with error handling
  (condition-case err
      (with-current-buffer (get-buffer-create knockknock--buffer)
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert message)))
    (error
     (message "knockknock: Error creating alert buffer: %s" err)))

  ;; Get colors at display time to ensure theme colors are used
  (let* ((base-bg-color (or knockknock-background-color
                           (face-background 'default nil t)))
         ;; Apply darken/lighten adjustments
         (bg-color (knockknock--adjust-background-color base-bg-color))
         (fg-color (or knockknock-foreground-color
                      (face-foreground 'default nil t))))
    ;; Display posframe with color parameters from current theme
    (condition-case err
        (posframe-show
         knockknock--buffer
         :poshandler knockknock-poshandler
         :internal-border-width knockknock-border-width
         :internal-border-color knockknock-border-color
         :left-fringe knockknock-left-fringe
         :right-fringe knockknock-right-fringe
         :background-color bg-color
         :foreground-color fg-color)
      (error
       (message "knockknock: Error showing posframe: %s" err))))

  ;; Hide after specified duration
  (setq knockknock--timer
        (run-with-timer duration nil #'knockknock-close)))

;;;###autoload
(defun knockknock-alert (message &optional duration)
  "Display an alert MESSAGE in a posframe for DURATION seconds.
If DURATION is nil, use `knockknock-default-duration'.
During Emacs startup, alerts are queued and shown after the frame is ready."
  (interactive "sMessage: ")
  ;; Ensure knockknock is initialized
  (knockknock--ensure-initialized)

  (let ((duration (or duration knockknock-default-duration)))
    (if knockknock--frame-ready
        ;; Frame is ready - show alert immediately
        (knockknock--alert-internal message duration)
      ;; Frame not ready - queue as a notification
      (when knockknock-debug
        (message "knockknock: Queuing alert (frame not ready): %s" message))
      (push (list :message message :duration duration)
            knockknock--pending-notifications))))

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

(provide 'knockknock)

;;; knockknock.el ends here
