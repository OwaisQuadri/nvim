;; extends

; nvim-treesitter's Swift query colors `class`/`struct`/`enum` but has no rule for
; `actor`, so it renders as plain text in every colorscheme. The parser already
; emits it as a keyword token -- this just gives it the same group.
"actor" @keyword.type
