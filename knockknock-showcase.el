;;; knockknock-showcase.el --- Showcase different knockknock configurations -*- lexical-binding: t; -*-

;; This file contains example configurations for taking screenshots
;; of the knockknock notification package.

;;; Code:

(require 'knockknock)

;;; Helper function to reset to defaults
(defun knockknock-showcase-reset ()
  "Reset knockknock to default settings."
  (setq knockknock-default-duration 3
        knockknock-border-width 1
        knockknock-border-color nil
        knockknock-background-color nil
        knockknock-foreground-color nil
        knockknock-left-fringe 8
        knockknock-right-fringe 8
        knockknock-poshandler #'posframe-poshandler-window-bottom-right-corner
        knockknock-icon-size 2.0
        knockknock-icon-padding 2
        knockknock-text-column 4
        knockknock-default-icon "nf-fa-info_circle"
        knockknock-use-icons t
        knockknock-use-svg-layout t
        knockknock-svg-icon-size 32
        knockknock-svg-width 350
        knockknock-svg-padding 12
        knockknock-max-message-width 40))

;;; 1. Basic Examples - Different Icons

(defun knockknock-showcase-1-success ()
  "Show success notification with check icon."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :title "Build Complete"
                     :message "All tests passed successfully!"
                     :icon "nf-cod-check"
                     :duration 10))

(defun knockknock-showcase-2-error ()
  "Show error notification with error icon."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :title "Build Failed"
                     :message "Compilation error in main.c line 42"
                     :icon "nf-cod-error"
                     :duration 10))

(defun knockknock-showcase-3-warning ()
  "Show warning notification."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :title "Warning"
                     :message "Deprecated function detected"
                     :icon "nf-cod-warning"
                     :duration 10))

(defun knockknock-showcase-4-info ()
  "Show info notification."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :title "Information"
                     :message "Process completed"
                     :icon "nf-cod-info"
                     :duration 10))

(defun knockknock-showcase-5-bell ()
  "Show bell notification."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :title "Reminder"
                     :message "Meeting starts in 5 minutes"
                     :icon "nf-cod-bell"
                     :duration 10))

(defun knockknock-showcase-6-rocket ()
  "Show rocket notification for deployment."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :title "Deployment"
                     :message "Successfully deployed to production"
                     :icon "nf-cod-rocket"
                     :duration 10))

(defun knockknock-showcase-7-download ()
  "Show download complete notification."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :title "Download Complete"
                     :message "package.tar.gz downloaded"
                     :icon "nf-cod-cloud_download"
                     :duration 10))

(defun knockknock-showcase-8-git ()
  "Show git notification."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :title "Git Push"
                     :message "Successfully pushed to origin/main"
                     :icon "nf-dev-git"
                     :duration 10))

;;; 2. Different Icon Families

(defun knockknock-showcase-9-octicon ()
  "Show octicon icon family."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :title "GitHub"
                     :message "Pull request merged"
                     :icon "nf-oct-mark_github"
                     :duration 10))

(defun knockknock-showcase-10-faicon ()
  "Show font-awesome icon family."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :title "Heart"
                     :message "Added to favorites"
                     :icon "nf-fa-heart"
                     :duration 10))

(defun knockknock-showcase-11-mdicon ()
  "Show material design icon family."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :title "Email"
                     :message "New message received"
                     :icon "nf-md-email"
                     :duration 10))

;;; 3. Different Positions

(defun knockknock-showcase-12-top-left ()
  "Show notification in top-left corner."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-poshandler #'posframe-poshandler-window-top-left-corner)
  (knockknock-notify :title "Top Left"
                     :message "Notification positioned at top-left"
                     :icon "nf-cod-arrow_up"
                     :duration 10))

(defun knockknock-showcase-13-top-right ()
  "Show notification in top-right corner."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-poshandler #'posframe-poshandler-window-top-right-corner)
  (knockknock-notify :title "Top Right"
                     :message "Notification positioned at top-right"
                     :icon "nf-cod-arrow_up"
                     :duration 10))

(defun knockknock-showcase-14-bottom-left ()
  "Show notification in bottom-left corner."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-poshandler #'posframe-poshandler-window-bottom-left-corner)
  (knockknock-notify :title "Bottom Left"
                     :message "Notification positioned at bottom-left"
                     :icon "nf-cod-arrow_down"
                     :duration 10))

(defun knockknock-showcase-15-bottom-right ()
  "Show notification in bottom-right corner (default)."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-poshandler #'posframe-poshandler-window-bottom-right-corner)
  (knockknock-notify :title "Bottom Right"
                     :message "Notification positioned at bottom-right"
                     :icon "nf-cod-arrow_down"
                     :duration 10))

(defun knockknock-showcase-16-center ()
  "Show notification in center."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-poshandler #'posframe-poshandler-window-center)
  (knockknock-notify :title "Center"
                     :message "Notification positioned at center"
                     :icon "nf-cod-target"
                     :duration 10))

;;; 4. SVG vs Text Layout

(defun knockknock-showcase-17-svg-layout ()
  "Show notification with SVG layout (default)."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-use-svg-layout t)
  (knockknock-notify :title "SVG Layout"
                     :message "Using SVG for pixel-perfect positioning"
                     :icon "nf-cod-symbol_color"
                     :duration 10))

(defun knockknock-showcase-18-text-layout ()
  "Show notification with text layout."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-use-svg-layout nil)
  (knockknock-notify :title "Text Layout"
                     :message "Using text-based layout with nerd-icons"
                     :icon "nf-cod-symbol_string"
                     :duration 10))

;;; 5. Custom Colors

(defun knockknock-showcase-19-dark-theme ()
  "Show notification with dark theme colors."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-background-color "#1e1e1e"
        knockknock-foreground-color "#d4d4d4"
        knockknock-border-color "#3e3e3e")
  (knockknock-notify :title "Dark Theme"
                     :message "Custom dark background and foreground"
                     :icon "nf-cod-symbol_color"
                     :duration 10))

(defun knockknock-showcase-20-light-theme ()
  "Show notification with light theme colors."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-background-color "#ffffff"
        knockknock-foreground-color "#000000"
        knockknock-border-color "#cccccc")
  (knockknock-notify :title "Light Theme"
                     :message "Custom light background and foreground"
                     :icon "nf-cod-symbol_color"
                     :duration 10))

(defun knockknock-showcase-21-blue-theme ()
  "Show notification with blue accent."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-background-color "#1e3a5f"
        knockknock-foreground-color "#e1f5fe"
        knockknock-border-color "#2196f3")
  (knockknock-notify :title "Blue Theme"
                     :message "Ocean blue color scheme"
                     :icon "nf-cod-symbol_color"
                     :duration 10))

(defun knockknock-showcase-22-green-theme ()
  "Show notification with green accent."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-background-color "#1b5e20"
        knockknock-foreground-color "#e8f5e9"
        knockknock-border-color "#4caf50")
  (knockknock-notify :title "Green Theme"
                     :message "Forest green color scheme"
                     :icon "nf-cod-symbol_color"
                     :duration 10))

(defun knockknock-showcase-23-red-theme ()
  "Show notification with red accent."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-background-color "#5f1e1e"
        knockknock-foreground-color "#ffebee"
        knockknock-border-color "#f44336")
  (knockknock-notify :title "Red Theme"
                     :message "Alert red color scheme"
                     :icon "nf-cod-symbol_color"
                     :duration 10))

(defun knockknock-showcase-23a-dark-red-text ()
  "Show notification with dark background and red text."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-background-color "#1e1e1e"
        knockknock-border-color "#ff4444")
  (set-face-attribute 'knockknock-title-face nil
                      :foreground "#ff4444"
                      :weight 'bold
                      :height 1.3)
  (set-face-attribute 'knockknock-message-face nil
                      :foreground "#ffaaaa"
                      :height 1.0)
  (set-face-attribute 'knockknock-icon-face nil
                      :foreground "#ff4444")
  (knockknock-notify :title "Error Alert"
                     :message "Something went wrong with your operation"
                     :icon "nf-cod-error"
                     :duration 10))

(defun knockknock-showcase-23b-dark-green-text ()
  "Show notification with dark background and green text."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-background-color "#1e1e1e"
        knockknock-border-color "#4caf50")
  (set-face-attribute 'knockknock-title-face nil
                      :foreground "#4caf50"
                      :weight 'bold
                      :height 1.3)
  (set-face-attribute 'knockknock-message-face nil
                      :foreground "#a5d6a7"
                      :height 1.0)
  (set-face-attribute 'knockknock-icon-face nil
                      :foreground "#4caf50")
  (knockknock-notify :title "Success"
                     :message "All tests passed successfully"
                     :icon "nf-cod-check"
                     :duration 10))

(defun knockknock-showcase-23c-dark-blue-text ()
  "Show notification with dark background and blue text."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-background-color "#1e1e1e"
        knockknock-border-color "#2196f3")
  (set-face-attribute 'knockknock-title-face nil
                      :foreground "#2196f3"
                      :weight 'bold
                      :height 1.3)
  (set-face-attribute 'knockknock-message-face nil
                      :foreground "#90caf9"
                      :height 1.0)
  (set-face-attribute 'knockknock-icon-face nil
                      :foreground "#2196f3")
  (knockknock-notify :title "Information"
                     :message "Process completed at 14:32"
                     :icon "nf-cod-info"
                     :duration 10))

(defun knockknock-showcase-23d-dark-orange-text ()
  "Show notification with dark background and orange text."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-background-color "#1e1e1e"
        knockknock-border-color "#ff9800")
  (set-face-attribute 'knockknock-title-face nil
                      :foreground "#ff9800"
                      :weight 'bold
                      :height 1.3)
  (set-face-attribute 'knockknock-message-face nil
                      :foreground "#ffcc80"
                      :height 1.0)
  (set-face-attribute 'knockknock-icon-face nil
                      :foreground "#ff9800")
  (knockknock-notify :title "Warning"
                     :message "Deprecated function in use"
                     :icon "nf-cod-warning"
                     :duration 10))

;;; 6. Different Border Widths

(defun knockknock-showcase-24-no-border ()
  "Show notification without border."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-border-width 0)
  (knockknock-notify :title "No Border"
                     :message "Notification without border"
                     :icon "nf-cod-chrome_minimize"
                     :duration 10))

(defun knockknock-showcase-25-thick-border ()
  "Show notification with thick border."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-border-width 5
        knockknock-border-color "#4caf50")
  (knockknock-notify :title "Thick Border"
                     :message "Notification with 5px green border"
                     :icon "nf-cod-chrome_maximize"
                     :duration 10))

(defun knockknock-showcase-26-colored-border ()
  "Show notification with colored border."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-border-width 3
        knockknock-border-color "#ff9800")
  (knockknock-notify :title "Colored Border"
                     :message "Notification with orange border"
                     :icon "nf-cod-paintcan"
                     :duration 10))

;;; 7. Different Icon Sizes

(defun knockknock-showcase-27-small-icon ()
  "Show notification with small icon (SVG)."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-svg-icon-size 20)
  (knockknock-notify :title "Small Icon"
                     :message "Icon size: 20 pixels"
                     :icon "nf-cod-dashboard"
                     :duration 10))

(defun knockknock-showcase-28-large-icon ()
  "Show notification with large icon (SVG)."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-svg-icon-size 48)
  (knockknock-notify :title "Large Icon"
                     :message "Icon size: 48 pixels"
                     :icon "nf-cod-dashboard"
                     :duration 10))

(defun knockknock-showcase-29-huge-icon ()
  "Show notification with huge icon (SVG)."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-svg-icon-size 64
        knockknock-svg-width 400)
  (knockknock-notify :title "Huge Icon"
                     :message "Icon size: 64 pixels with wider canvas"
                     :icon "nf-cod-dashboard"
                     :duration 10))

;;; 8. Text Layout - Different Icon Sizes

(defun knockknock-showcase-30-text-small-icon ()
  "Show text layout with small icon."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-use-svg-layout nil
        knockknock-icon-size 1.5)
  (knockknock-notify :title "Small Icon"
                     :message "Text layout with 1.5x icon size"
                     :icon "nf-cod-beaker"
                     :duration 10))

(defun knockknock-showcase-31-text-large-icon ()
  "Show text layout with large icon."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-use-svg-layout nil
        knockknock-icon-size 3.0)
  (knockknock-notify :title "Large Icon"
                     :message "Text layout with 3.0x icon size"
                     :icon "nf-cod-beaker"
                     :duration 10))

;;; 9. Without Icons

(defun knockknock-showcase-32-no-icon ()
  "Show notification without icon."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-use-icons nil)
  (knockknock-notify :title "No Icon"
                     :message "Notification without icon"
                     :duration 10))

(defun knockknock-showcase-33-text-only ()
  "Show notification with only message, no title or icon."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-use-icons nil)
  (knockknock-notify :message "Simple text-only notification"
                     :duration 10))

;;; 10. Long Messages - Text Wrapping

(defun knockknock-showcase-34-wrapped-message ()
  "Show notification with long wrapped message."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :title "Long Message"
                     :message "This is a very long message that will be automatically wrapped to multiple lines to fit within the notification frame. The wrapping respects word boundaries."
                     :icon "nf-cod-word_wrap"
                     :duration 10))

(defun knockknock-showcase-35-narrow-wrap ()
  "Show notification with narrow text wrapping."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-max-message-width 25
        knockknock-svg-width 250)
  (knockknock-notify :title "Narrow Width"
                     :message "This message wraps at 25 characters per line making it appear narrower."
                     :icon "nf-cod-fold"
                     :duration 10))

(defun knockknock-showcase-36-wide-wrap ()
  "Show notification with wide text wrapping."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-max-message-width 60
        knockknock-svg-width 450)
  (knockknock-notify :title "Wide Width"
                     :message "This message can be much longer per line with 60 characters maximum width allowing more text to fit on each line before wrapping."
                     :icon "nf-cod-unfold"
                     :duration 10))

;;; 11. Different Fringe Widths

(defun knockknock-showcase-37-no-fringe ()
  "Show notification without fringe."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-left-fringe 0
        knockknock-right-fringe 0)
  (knockknock-notify :title "No Fringe"
                     :message "Notification without left/right fringe"
                     :icon "nf-cod-arrow_both"
                     :duration 10))

(defun knockknock-showcase-38-wide-fringe ()
  "Show notification with wide fringe."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-left-fringe 20
        knockknock-right-fringe 20)
  (knockknock-notify :title "Wide Fringe"
                     :message "Notification with 20px left/right fringe"
                     :icon "nf-cod-arrow_both"
                     :duration 10))

;;; 12. Title-only and Message-only

(defun knockknock-showcase-39-title-only ()
  "Show notification with only title."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :title "Title Only Notification"
                     :icon "nf-cod-symbol_text"
                     :duration 10))

(defun knockknock-showcase-40-message-only ()
  "Show notification with only message."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :message "Message only notification"
                     :icon "nf-cod-comment"
                     :duration 10))

;;; 13. Real-world Use Cases

(defun knockknock-showcase-41-compile-success ()
  "Show realistic compile success notification."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-border-color "#4caf50"
        knockknock-border-width 2)
  (knockknock-notify :title "Compilation Successful"
                     :message "Compiled 142 files in 3.2 seconds"
                     :icon "nf-cod-check"
                     :duration 10))

(defun knockknock-showcase-42-compile-error ()
  "Show realistic compile error notification."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-border-color "#f44336"
        knockknock-border-width 2)
  (knockknock-notify :title "Compilation Failed"
                     :message "3 errors, 5 warnings. See *compilation* buffer."
                     :icon "nf-cod-error"
                     :duration 10))

(defun knockknock-showcase-43-test-passed ()
  "Show realistic test passed notification."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-border-color "#4caf50"
        knockknock-border-width 2)
  (knockknock-notify :title "Tests Passed"
                     :message "All 47 tests passed in 12.3 seconds"
                     :icon "nf-cod-check_all"
                     :duration 10))

(defun knockknock-showcase-44-test-failed ()
  "Show realistic test failed notification."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-border-color "#f44336"
        knockknock-border-width 2)
  (knockknock-notify :title "Tests Failed"
                     :message "3 of 47 tests failed. 2 errors, 1 timeout."
                     :icon "nf-cod-close"
                     :duration 10))

(defun knockknock-showcase-45-save-reminder ()
  "Show save file reminder."
  (interactive)
  (knockknock-showcase-reset)
  (setq knockknock-border-color "#ff9800"
        knockknock-border-width 2)
  (knockknock-notify :title "Unsaved Changes"
                     :message "You have unsaved changes in 3 files"
                     :icon "nf-cod-save"
                     :duration 10))

(defun knockknock-showcase-46-git-commit ()
  "Show git commit notification."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :title "Commit Created"
                     :message "feat: add new notification system"
                     :icon "nf-dev-git_commit"
                     :duration 10))

(defun knockknock-showcase-47-package-installed ()
  "Show package installation notification."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :title "Package Installed"
                     :message "Successfully installed magit-3.4.0"
                     :icon "nf-cod-package"
                     :duration 10))

(defun knockknock-showcase-48-server-started ()
  "Show server started notification."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-notify :title "Server Started"
                     :message "Development server running on port 3000"
                     :icon "nf-cod-server"
                     :duration 10))

;;; 14. Legacy API (knockknock-alert)

(defun knockknock-showcase-49-legacy-simple ()
  "Show simple legacy notification."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-alert "Simple alert message"))

(defun knockknock-showcase-50-legacy-duration ()
  "Show legacy notification with custom duration."
  (interactive)
  (knockknock-showcase-reset)
  (knockknock-alert "Alert with 5 second duration" 5))

;;; Helper function to run all examples

(defun knockknock-showcase-all ()
  "Run all showcase examples with delays.
This will display each example for 3 seconds."
  (interactive)
  (let ((showcase-functions
         '(knockknock-showcase-1-success
           knockknock-showcase-2-error
           knockknock-showcase-3-warning
           knockknock-showcase-4-info
           knockknock-showcase-5-bell
           knockknock-showcase-6-rocket
           knockknock-showcase-7-download
           knockknock-showcase-8-git
           knockknock-showcase-9-octicon
           knockknock-showcase-10-faicon
           knockknock-showcase-11-mdicon
           knockknock-showcase-12-top-left
           knockknock-showcase-13-top-right
           knockknock-showcase-14-bottom-left
           knockknock-showcase-15-bottom-right
           knockknock-showcase-16-center
           knockknock-showcase-17-svg-layout
           knockknock-showcase-18-text-layout
           knockknock-showcase-19-dark-theme
           knockknock-showcase-20-light-theme
           knockknock-showcase-21-blue-theme
           knockknock-showcase-22-green-theme
           knockknock-showcase-23-red-theme
           knockknock-showcase-24-no-border
           knockknock-showcase-25-thick-border
           knockknock-showcase-26-colored-border
           knockknock-showcase-27-small-icon
           knockknock-showcase-28-large-icon
           knockknock-showcase-29-huge-icon
           knockknock-showcase-30-text-small-icon
           knockknock-showcase-31-text-large-icon
           knockknock-showcase-32-no-icon
           knockknock-showcase-33-text-only
           knockknock-showcase-34-wrapped-message
           knockknock-showcase-35-narrow-wrap
           knockknock-showcase-36-wide-wrap
           knockknock-showcase-37-no-fringe
           knockknock-showcase-38-wide-fringe
           knockknock-showcase-39-title-only
           knockknock-showcase-40-message-only
           knockknock-showcase-41-compile-success
           knockknock-showcase-42-compile-error
           knockknock-showcase-43-test-passed
           knockknock-showcase-44-test-failed
           knockknock-showcase-45-save-reminder
           knockknock-showcase-46-git-commit
           knockknock-showcase-47-package-installed
           knockknock-showcase-48-server-started
           knockknock-showcase-49-legacy-simple
           knockknock-showcase-50-legacy-duration)))
    (message "Starting showcase of %d examples..." (length showcase-functions))
    (dolist (func showcase-functions)
      (funcall func)
      (sit-for 3))))

(provide 'knockknock-showcase)

;;; knockknock-showcase.el ends here
