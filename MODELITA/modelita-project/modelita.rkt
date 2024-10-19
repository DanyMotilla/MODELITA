#lang racket
(require db)
(require math/matrix)

; Connect to PostGIS database
(define db-conn
  (postgresql-connect #:database "gisdb"
                      #:user "postgres"
                      #:password "modelita123"
                      #:server "localhost"
                      #:port 5432))

; Define our base symbols
(define base-symbols '(up down left right forward backward a b select start 
                      rotate-x+ rotate-x- rotate-y+ rotate-y- rotate-z+ rotate-z-
                      push pop))

; Custom symbol storage (will store user-defined symbols)
(define custom-symbols (make-hash))

; Define our current state
(define current-position (list 0 0 0))
(define current-shape '())
(define position-stack '())
(define rotation-matrix (matrix [[1 0 0]
                               [0 1 0]
                               [0 0 1]]))
(define matrix-stack '())

; Maximum recursion depth (to prevent infinite recursion)
(define max-recursion-depth 10)

; Helper functions for 3D operations and matrix manipulation
(define (matrix-multiply m1 m2)
  (matrix* m1 m2))

(define (vec->matrix vec)
  (matrix [[(first vec)]
           [(second vec)]
           [(third vec)]]))

(define (matrix->vec mat)
  (list (matrix-ref mat 0 0)
        (matrix-ref mat 1 0)
        (matrix-ref mat 2 0)))

(define (rotate-x angle)
  (let* ([c (cos angle)]
         [s (sin angle)]
         [rx (matrix [[1.0 0.0  0.0]
                     [0.0 c    (- s)]
                     [0.0 s    c]])])
    (set! rotation-matrix (matrix-multiply rotation-matrix rx))))

(define (rotate-y angle)
  (let* ([c (cos angle)]
         [s (sin angle)]
         [ry (matrix [[c     0.0  s]
                     [0.0    1.0  0.0]
                     [(- s)  0.0  c]])])
    (set! rotation-matrix (matrix-multiply rotation-matrix ry))))

(define (rotate-z angle)
  (let* ([c (cos angle)]
         [s (sin angle)]
         [rz (matrix [[c    (- s) 0.0]
                     [s     c    0.0]
                     [0.0   0.0  1.0]])])
    (set! rotation-matrix (matrix-multiply rotation-matrix rz))))

(define (apply-rotation vec)
  (let* ([vec-matrix (vec->matrix vec)]
         [rotated (matrix-multiply rotation-matrix vec-matrix)])
    (matrix->vec rotated)))

(define (move-3d x y z)
  (let ([movement (apply-rotation (list x y z))])
    (set! current-position 
          (list (+ (first current-position) (first movement))
                (+ (second current-position) (second movement))
                (+ (third current-position) (third movement))))))

(define (push-state)
  (set! position-stack (cons current-position position-stack))
  (set! matrix-stack (cons rotation-matrix matrix-stack)))

(define (pop-state)
  (when (and (not (null? position-stack)) (not (null? matrix-stack)))
    (set! current-position (car position-stack))
    (set! position-stack (cdr position-stack))
    (set! rotation-matrix (car matrix-stack))
    (set! matrix-stack (cdr matrix-stack))))

(define (add-vertex)
  (set! current-shape (cons current-position current-shape)))

; Process a symbol with recursion depth control
(define (process-symbol symbol depth)
  (when (<= depth max-recursion-depth)
    (cond
      [(hash-has-key? custom-symbols symbol)
       (for-each (λ (s) (process-symbol s (add1 depth)))
                 (hash-ref custom-symbols symbol))]
      [else
       (case symbol
         [(up) (move-3d 0 1 0)]
         [(down) (move-3d 0 -1 0)]
         [(left) (move-3d -1 0 0)]
         [(right) (move-3d 1 0 0)]
         [(forward) (move-3d 0 0 1)]
         [(backward) (move-3d 0 0 -1)]
         [(rotate-x+) (rotate-x (/ pi 2))]
         [(rotate-x-) (rotate-x (/ pi -2))]
         [(rotate-y+) (rotate-y (/ pi 2))]
         [(rotate-y-) (rotate-y (/ pi -2))]
         [(rotate-z+) (rotate-z (/ pi 2))]
         [(rotate-z-) (rotate-z (/ pi -2))]
         [(push) (push-state)]
         [(pop) (pop-state)]
         [(a) (add-vertex)]
         [(b) (set! current-shape '())]
         [(select) (printf "Current position: ~a\n" current-position)]
         [(start) (save-obj "output.obj")
                 (printf "Shape saved to models/output.obj\n")])])))

; Modified function to save the current shape as an .obj file in the models directory
(define (save-obj filename)
  (let ([full-path (build-path "models" filename)])
    (with-output-to-file full-path
      (lambda ()
        (for ([vertex (reverse current-shape)]
              [index (in-naturals 1)])
          (printf "v ~a ~a ~a\n" 
                  (first vertex) 
                  (second vertex) 
                  (third vertex)))
        (printf "f")
        (for ([index (in-range 1 (add1 (length current-shape)))])
          (printf " ~a" index))
        (newline))
      #:exists 'replace)))

; Function to define a new symbol
(define (define-symbol name commands)
  (hash-set! custom-symbols name commands)
  (printf "Symbol '~a' defined\n" name))

; Function to save a symbol to file
(define (save-symbol-to-file name commands filename)
  (with-output-to-file (string-append "symbols/" filename ".sym")
    (lambda ()
      (write commands))
    #:exists 'replace))

; Function to save a symbol
(define (save-symbol name)
  (when (hash-has-key? custom-symbols name)
    (save-symbol-to-file name 
                        (hash-ref custom-symbols name)
                        (symbol->string name))
    (printf "Symbol '~a' saved to file\n" name)))

; Function to load symbol definitions from file
(define (load-symbol-from-file filename)
  (with-input-from-file (string-append "symbols/" filename ".sym")
    read))

; Function to load a symbol
(define (load-symbol filename)
  (let ([name (string->symbol filename)]
        [commands (load-symbol-from-file filename)])
    (define-symbol name commands)
    (printf "Symbol '~a' loaded from file\n" name)))

; Enhanced main loop
(define (main-loop)
  (display "Enter command (symbol or define/save/load/quit): ")
  (flush-output)
  (let ([input (read)])
    (cond
      [(eq? input 'quit)
       (displayln "Exiting program.")]
      [(eq? input 'define)
       (display "Enter new symbol name: ")
       (let ([name (read)])
         (display "Enter commands (as list): ")
         (let ([commands (read)])
           (define-symbol name commands)))
       (main-loop)]
      [(eq? input 'save)
       (display "Enter symbol name to save: ")
       (save-symbol (read))
       (main-loop)]
      [(eq? input 'load)
       (display "Enter symbol filename to load: ")
       (load-symbol (symbol->string (read)))
       (main-loop)]
      [(or (member input base-symbols)
           (hash-has-key? custom-symbols input))
       (process-symbol input 0)
       (main-loop)]
      [else
       (displayln "Invalid command. Please try again.")
       (main-loop)])))

; Create required directories if they don't exist
(make-directory* "symbols")
(make-directory* "models")

; Start the program
(main-loop)

; Close database connection
(disconnect db-conn)
