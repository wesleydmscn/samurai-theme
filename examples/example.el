(defpackage #:shop
  (:use #:cl)
  (:export #:main))

(in-package #:shop)

(defstruct product
  (id   "" :type string  :read-only t)
  (name "" :type string  :read-only t)
  (price 0 :type number  :read-only t)
  (stock 0 :type integer :read-only t))

(defstruct cart-item
  (product nil :read-only t)
  (qty     1   :type integer))

(defun make-repository ()
  (let ((store (make-hash-table :test #'equal)))
    (list
     :save   (lambda (key val) (setf (gethash key store) val))
     :find   (lambda (key)     (gethash key store))
     :all    (lambda ()        (loop for v being the hash-values of store collect v)))))

(defun repo-save  (repo key val) (funcall (getf repo :save) key val))
(defun repo-find  (repo key)     (funcall (getf repo :find) key))
(defun repo-all   (repo)         (funcall (getf repo :all)))

(defun cart-add (items product qty)
  (let ((existing (find (product-id product) items
                        :key (lambda (i) (product-id (cart-item-product i)))
                        :test #'equal)))
    (if existing
        (progn
          (incf (cart-item-qty existing) qty)
          items)
        (cons (make-cart-item :product product :qty qty) items))))

(defun cart-subtotal (items)
  (reduce #'+ items :key (lambda (i) (* (product-price (cart-item-product i))
                                         (cart-item-qty i)))
          :initial-value 0))

(defgeneric apply-discount (strategy price))

(defstruct percentage-discount (rate 0 :type number))
(defstruct fixed-discount       (amount 0 :type number))

(defmethod apply-discount ((d percentage-discount) price)
  (* price (- 1 (/ (percentage-discount-rate d) 100.0))))

(defmethod apply-discount ((d fixed-discount) price)
  (max 0 (- price (fixed-discount-amount d))))

(defun fibonacci (n)
  (loop with a = 0 and b = 1
        repeat n
        collect a
        do (psetq a b b (+ a b))))

(defun sieve (limit)
  (let ((flags (make-array (1+ limit) :element-type 'boolean :initial-element t)))
    (setf (aref flags 0) nil
          (aref flags 1) nil)
    (loop for i from 2 to (isqrt limit)
          when (aref flags i)
          do (loop for j from (* i i) to limit by i
                   do (setf (aref flags j) nil)))
    (loop for i from 2 to limit when (aref flags i) collect i)))

(defun main ()
  (let ((repo (make-repository)))
    (repo-save repo "1" (make-product :id "1" :name "Laptop"   :price 999.99 :stock 10))
    (repo-save repo "2" (make-product :id "2" :name "Mouse"    :price  29.99 :stock 50))
    (repo-save repo "3" (make-product :id "3" :name "Keyboard" :price  79.99 :stock 30))

    (let* ((cart (cart-add
                  (cart-add '() (repo-find repo "1") 1)
                  (repo-find repo "2") 2))
           (subtotal  (cart-subtotal cart))
           (discount  (make-percentage-discount :rate 10))
           (discounted (apply-discount discount subtotal)))

      (format t "Subtotal:   $~,2f~%" subtotal)
      (format t "After 10%%: $~,2f~%" discounted))

    (let ((affordable (sort (remove-if-not (lambda (p) (< (product-price p) 100))
                                           (repo-all repo))
                            #'< :key #'product-price)))
      (format t "Affordable: ~{~a~^, ~}~%" (mapcar #'product-name affordable)))

    (format t "Fibonacci(8): ~a~%" (fibonacci 8))
    (format t "Primes up to 30: ~a~%" (sieve 30))))

(main)
