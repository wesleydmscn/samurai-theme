module Main where

import Data.List (intercalate, sortBy)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Ord (comparing)

data Product = Product
  { productId    :: String
  , productName  :: String
  , productPrice :: Double
  , productStock :: Int
  } deriving (Show, Eq)

data CartItem = CartItem
  { cartProduct  :: Product
  , cartQty      :: Int
  } deriving (Show)

itemSubtotal :: CartItem -> Double
itemSubtotal item = productPrice (cartProduct item) * fromIntegral (cartQty item)

newtype Cart = Cart { cartItems :: Map String CartItem }

emptyCart :: Cart
emptyCart = Cart Map.empty

addToCart :: Product -> Int -> Cart -> Cart
addToCart product qty (Cart items) =
  Cart $ Map.insertWith merge (productId product) newItem items
  where
    newItem = CartItem product qty
    merge _ old = old { cartQty = cartQty old + qty }

cartSubtotal :: Cart -> Double
cartSubtotal = sum . map itemSubtotal . Map.elems . cartItems

newtype Discount = Discount { applyDiscount :: Double -> Double }

percentageDiscount :: Double -> Discount
percentageDiscount rate = Discount $ \price -> price * (1 - rate / 100)

fixedDiscount :: Double -> Discount
fixedDiscount amount = Discount $ \price -> max 0 (price - amount)

cartTotal :: Cart -> Maybe Discount -> Double
cartTotal cart Nothing         = cartSubtotal cart
cartTotal cart (Just discount) = applyDiscount discount (cartSubtotal cart)

newtype Repository a = Repository { repoStore :: Map String a }

emptyRepo :: Repository a
emptyRepo = Repository Map.empty

repoSave :: String -> a -> Repository a -> Repository a
repoSave key entity (Repository store) = Repository (Map.insert key entity store)

repoFind :: String -> Repository a -> Maybe a
repoFind key (Repository store) = Map.lookup key store

repoAll :: Repository a -> [a]
repoAll (Repository store) = Map.elems store

fibonacci :: Int -> [Integer]
fibonacci n = take n fibs
  where fibs = 0 : 1 : zipWith (+) fibs (tail fibs)

sieve :: Int -> [Int]
sieve limit = go [2..limit]
  where
    go []     = []
    go (p:xs) = p : go [x | x <- xs, x `mod` p /= 0]

safeDivide :: Double -> Double -> Either String Double
safeDivide _ 0 = Left "Division by zero"
safeDivide a b = Right (a / b)

formatDouble :: Double -> String
formatDouble x = show (fromIntegral (round (x * 100) :: Int) `div` 100 :: Int)
              ++ "."
              ++ show (abs (round (x * 100) `mod` 100) :: Int)

main :: IO ()
main = do
  let repo = foldr (uncurry repoSave) emptyRepo
        [ ("1", Product "1" "Laptop"   999.99 10)
        , ("2", Product "2" "Mouse"     29.99 50)
        , ("3", Product "3" "Keyboard"  79.99 30)
        ]

  let cart = case (repoFind "1" repo, repoFind "2" repo) of
        (Just laptop, Just mouse) ->
          addToCart mouse 2 . addToCart laptop 1 $ emptyCart
        _ -> emptyCart

  let discount = percentageDiscount 10
  putStrLn $ "Subtotal:   $" ++ show (cartSubtotal cart)
  putStrLn $ "After 10%: $" ++ show (cartTotal cart (Just discount))

  let affordable = sortBy (comparing productPrice)
                 $ filter (\p -> productPrice p < 100) (repoAll repo)
  putStrLn $ "Affordable: " ++ intercalate ", " (map productName affordable)
  putStrLn $ "Fibonacci(8): " ++ show (fibonacci 8)
  putStrLn $ "Primes up to 30: " ++ show (sieve 30)

  case safeDivide 10 3 of
    Right v -> putStrLn $ "10 / 3 = " ++ show v
    Left  e -> putStrLn $ "Error: " ++ e
