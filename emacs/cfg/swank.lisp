; SRC: https://slime-tips.tumblr.com/post/18012685799/how-to-use-swanklisp
;   instead of using SETF, it’s better to use DEFVAR or DEFPARAMETER,
;   because ~/.swank.lisp is loaded before the contrib modules (in which some
;   variables are defined) and SETF will produce a warning (like in the previous
;   tip) or may not work at all.
(in-package :swank)
; REF: https://slime.common-lisp.dev/doc/html/Other-configurables.html
(defparameter swank:*globally-redirect-io* t)
; (setf swank:*communication-style* :fd-handler)
