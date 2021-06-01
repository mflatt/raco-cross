#lang racket/base

(require racket/list)
(provide default-vm
         default-version
         default-installers-url)

(define (default-vm)
  (case (system-type 'vm)
    [(chez-scheme) 'cs]
    [else 'bc]))

(define version-regexp #rx"^([0-9]+.[0-9]+)(?:.([0-9][0-0]*))?(?:.([0-9][0-0]*))?")

(define (default-version)
  (cadr (regexp-match version-regexp (version))))

(define (default-installers-url vers)
  (cond
    [(and (>= 10 (string-length vers))
          (regexp-match #rx"[0-9a-f]+" vers))
     (format "https://ci-snapshot.racket-lang.org/~a/installers/" (substring vers 0 10))]
    [(let ([v (regexp-match version-regexp vers)])
       (and v (equal? (third v) 900)))
     "https://pre-release.racket-lang.org/installers/"]
    [else
     (format "https://mirror.racket-lang.org/installers/~a/" vers)]))
