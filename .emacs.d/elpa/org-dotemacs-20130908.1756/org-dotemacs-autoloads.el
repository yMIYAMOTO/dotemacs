;;; org-dotemacs-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (org-dotemacs-load-file org-dotemacs-load-blocks
;;;;;;  org-dotemacs-extract-subtrees string-split) "org-dotemacs"
;;;;;;  "org-dotemacs.el" (21347 5059 25869 884000))
;;; Generated autoloads from org-dotemacs.el

(autoload 'string-split "org-dotemacs" "\
Split STRING at occurences of SEPARATOR.  Return a list of substrings.
Optional argument SEPARATOR can be any regexp, but anything matching the
 separator will never appear in any of the returned substrings.
 If not specified, SEPARATOR defaults to \"[ \\f\\t\\n\\r\\v]+\".
If optional arg LIMIT is specified, split into no more than that many
 fields (though it may split into fewer).

\(fn STRING &optional SEPARATOR LIMIT)" nil nil)

(autoload 'org-dotemacs-extract-subtrees "org-dotemacs" "\
Extract subtrees in current org-mode buffer that match tag MATCH.
MATCH should be a tag match as detailed in the org manual.
If EXCLUDE-TODO-STATE is non-nil then subtrees with todo states matching this regexp will be
excluding, and if INCLUDE-TODO-STATE is non-nil then only subtrees with todo states matching
this regexp will be included.
The copied subtrees will be placed in a new buffer which is returned by this function.
If called interactively MATCH is prompted from the user, and the new buffer containing
the copied subtrees will be visited.

\(fn MATCH &optional (exclude-todo-state org-dotemacs-exclude-todo) (include-todo-state org-dotemacs-include-todo))" t nil)

(autoload 'org-dotemacs-load-blocks "org-dotemacs" "\
Load the emacs-lisp code blocks in the current org-mode file.
Save the blocks to TARGET-FILE if it is non-nil.
See the definition of `org-dotemacs-error-handling' for an explanation of the ERROR-HANDLING
argument which uses `org-dotemacs-error-handling' for its default value.

\(fn &optional TARGET-FILE (error-handling org-dotemacs-error-handling))" nil nil)

(autoload 'org-dotemacs-load-file "org-dotemacs" "\
Load the elisp code from code blocks in org FILE under headers matching tag MATCH.
If TARGET-FILE is supplied it should be a filename to save the elisp code to, but it should
not be any of the default config files .emacs, .emacs.el, .emacs.elc or init.el
 (the function will halt with an error in those cases).
The optional argument ERROR-HANDLING determines how errors are handled and takes default value
`org-dotemacs-error-handling' (which see).

\(fn &optional MATCH (file org-dotemacs-default-file) TARGET-FILE (error-handling org-dotemacs-error-handling))" t nil)

;;;***

;;;### (autoloads nil nil ("org-dotemacs-pkg.el") (21347 5059 294652
;;;;;;  20000))

;;;***

(provide 'org-dotemacs-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; org-dotemacs-autoloads.el ends here
