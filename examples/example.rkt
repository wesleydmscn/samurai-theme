#lang racket/base

(require racket/list
         racket/string
         racket/match
         racket/generator)

(struct product (id name price stock) #:transparent)
(struct cart-item (product qty) #:transparent)

(define (make-repository)
  (let ([store (make-hash)])
    (define (save! entity key)
      (hash-set! store key entity))
    (define (find id)
      (hash-ref store id #f))
    (define (find-all)
      (hash-values store))
    (values save! find find-all)))

(define-values (save-product! find-product find-all-products)
  (make-repository))

(define (cart-add items product qty)
  (let* ([id (product-id product)]
         [existing (assoc id items)])
    (if existing
        (map (lambda (item)
               (if (equal? (car item) id)
                   (list id product (+ (caddr item) qty))
                   item))
             items)
        (cons (list id product qty) items))))

(define (cart-subtotal items)
  (foldl (lambda (item acc)
           (let ([prod (cadr item)]
                 [qty  (caddr item)])
             (+ acc (* (product-price prod) qty))))
         0
         items))

(define (apply-discount strategy price)
  (match strategy
    [`(percentage ,pct) (* price (- 1 (/ pct 100.0)))]
    [`(fixed ,amt)      (max 0 (- price amt))]
    ['none              price]))

(define (fibonacci n)
  (let loop ([a 0] [b 1] [acc '()] [k 0])
    (if (= k n)
        (reverse acc)
        (loop b (+ a b) (cons a acc) (+ k 1)))))

(define (sieve limit)
  (let ([flags (make-vector (+ limit 1) #t)])
    (vector-set! flags 0 #f)
    (vector-set! flags 1 #f)
    (for ([i (in-range 2 (+ 1 (exact-floor (sqrt limit))))])
      (when (vector-ref flags i)
        (for ([j (in-range (* i i) (+ limit 1) i)])
          (vector-set! flags j #f))))
    (for/list ([i (in-range 2 (+ limit 1))]
               #:when (vector-ref flags i))
      i)))

(define (safe-divide a b)
  (if (zero? b)
      (values #f "Division by zero")
      (values (/ a b) #f)))

(save-product! (product "1" "Laptop"   999.99 10) "1")
(save-product! (product "2" "Mouse"     29.99 50) "2")
(save-product! (product "3" "Keyboard"  79.99 30) "3")

(define cart
  (cart-add
   (cart-add '() (find-product "1") 1)
   (find-product "2") 2))

(define subtotal (cart-subtotal cart))
(define discounted (apply-discount '(percentage 10) subtotal))

(printf "Subtotal:    $~a~n" (real->decimal-string subtotal 2))
(printf "After 10%%:  $~a~n" (real->decimal-string discounted 2))

(define affordable
  (sort (filter (lambda (p) (< (product-price p) 100))
                (find-all-products))
        < #:key product-price))

(printf "Affordable: ~a~n" (map product-name affordable))
(printf "Fibonacci(8): ~a~n" (fibonacci 8))
(printf "Primes up to 30: ~a~n" (sieve 30))

(define-values (result err) (safe-divide 10 3))
(if err
    (printf "Error: ~a~n" err)
    (printf "10 / 3 = ~a~n" (exact->inexact result)))
