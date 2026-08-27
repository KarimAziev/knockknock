;;; knockknock-test.el --- Tests for knockknock -*- lexical-binding: t; -*-

(require 'ert)
(require 'knockknock)

(ert-deftest knockknock-action-activation ()
  "Activating a notification closes it and invokes its action."
  (let (activated closed)
    (with-temp-buffer
      (insert "Actionable notification")
      (knockknock--set-action (lambda () (setq activated t)))
      (should (eq (lookup-key (current-local-map) [mouse-1])
                  #'knockknock-activate))
      (should (eq (get-text-property (point-min) 'pointer) 'hand))
      (should (eq void-text-area-pointer 'hand))
      (should-not (get-text-property (point-min) 'mouse-face))
      (cl-letf (((symbol-function 'knockknock-close)
                 (lambda (&optional restore-focus)
                   (setq closed restore-focus))))
        (knockknock-activate)))
    (should (eq closed t))
    (should activated)))

(ert-deftest knockknock-notify-rejects-invalid-action ()
  "The public API rejects a non-function action."
  (should-error (knockknock-notify :title "Invalid" :action 42)
                :type 'error))

(ert-deftest knockknock-actionable-svg-has-pointer-and-hot-spots ()
  "An actionable SVG distinguishes activation from its close button."
  (skip-unless (image-type-available-p 'svg))
  (with-temp-buffer
    (let ((knockknock-use-icons nil))
      (knockknock--format-buffer-svg "Test" "Message" nil nil nil t))
    (let* ((image (get-text-property (point-min) 'display))
           (map (image-property image :original-map)))
      (should (eq (image-property image :pointer) 'hand))
      (should (eq (cadr (lookup-image-map map 299 2))
                  'knockknock-close))
      (should (eq (cadr (lookup-image-map map 100 50))
                  'knockknock-action))
      (should (eq (lookup-key knockknock--notification-map
                              [knockknock-close mouse-1])
                  #'knockknock-close))
      (should (eq (lookup-key knockknock--notification-map
                              [knockknock-action mouse-1])
                  #'knockknock-activate)))))

(ert-deftest knockknock-actionable-posframe-accepts-focus ()
  "An actionable notification makes its child frame interactive."
  (let (posframe-args)
    (cl-letf (((symbol-function 'posframe-show)
               (lambda (&rest args) (setq posframe-args args)))
              ((symbol-function 'run-with-timer)
               (lambda (&rest _args) 'test-timer)))
      (let ((knockknock--timer nil)
            (knockknock-use-svg-layout nil))
        (knockknock--notify-internal
         :title "Test"
         :message "Message"
         :duration 1
         :action #'ignore)))
    (should (eq (plist-get (cdr posframe-args) :accept-focus) t))))

(ert-deftest knockknock-interactive-close-restores-parent-focus ()
  "Closing an interactive child frame restores its parent's input focus."
  (let (hidden deleted focused-frame)
    (cl-letf (((symbol-function 'get-buffer)
               (lambda (_buffer) 'notification-buffer))
              ((symbol-function 'buffer-local-value)
               (lambda (_variable _buffer) 'notification-frame))
              ((symbol-function 'frame-live-p)
               (lambda (frame) (memq frame '(notification-frame parent-frame))))
              ((symbol-function 'frame-parent)
               (lambda (_frame) 'parent-frame))
              ((symbol-function 'posframe-hide)
               (lambda (_buffer) (setq hidden t)))
              ((symbol-function 'posframe-delete)
               (lambda (_buffer) (setq deleted t)))
              ((symbol-function 'select-frame-set-input-focus)
               (lambda (frame &optional _norecord)
                 (setq focused-frame frame))))
      (let ((knockknock--progress-state nil)
            (knockknock--timer nil))
        (knockknock-close t)))
    (should hidden)
    (should deleted)
    (should (eq focused-frame 'parent-frame))))

(ert-deftest knockknock-timed-close-does-not-steal-focus ()
  "A non-interactive close leaves the user's current frame focused."
  (let (focused-frame)
    (cl-letf (((symbol-function 'posframe-hide) #'ignore)
              ((symbol-function 'posframe-delete) #'ignore)
              ((symbol-function 'select-frame-set-input-focus)
               (lambda (frame &optional _norecord)
                 (setq focused-frame frame))))
      (let ((knockknock--progress-state nil)
            (knockknock--timer nil))
        (knockknock-close)))
    (should-not focused-frame)))

(provide 'knockknock-test)

;;; knockknock-test.el ends here
