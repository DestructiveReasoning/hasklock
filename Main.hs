import Control.Concurrent
import Data.Char
import Data.Maybe
import qualified Data.Text as Text
import Data.Time.LocalTime
import Numeric
import System.Environment
import System.Exit
import System.Posix.Process
import System.Posix.Signals
import UI.HSCurses.Curses
import UI.HSCurses.CursesHelper

-- TODO LIST                                STATUS
-- Custom colors                            Not started
-- Fix arguments after size                 Not started

led = convertAttributes[Reverse]

initColors = do
    initPair (Pair 1) (Color 60) defaultBackground
    initPair (Pair 2) (Color 233) defaultBackground

on = Pair 1
off = Pair 2

--scale = 4

findArgs :: Eq a => a -> [a] -> Int
findArgs x ls = 
    foldl (\i q -> if q == x then i else i + 1) 0 ls

scale :: IO Int
scale = do
    args <- getArgs
    if (length args) == 1 then return 4
    else do
        let sizeArg = (findArgs "-s" args) 
        if sizeArg == 0 then return 4
        else if sizeArg >= (length args) then return 4
        else return (read $ args !! sizeArg)

displayLED w y x color = do
--    putStrLn "illuminating LED"
    wAttrSet w (led, color)
    s <- scale
    draw (s `div` 2) s
    where draw 0 _ = return()
          draw i s = do
                  mvWAddStr w (y + i) x (take(s) (repeat ' '))
                  draw (i - 1) s
--    mvWAddStr w (y+1) x  "  "

displayColumnPair :: Window -> Int -> Int -> Int -> [Char] -> IO()
displayColumnPair _ _ _ _ [] = return ()
displayColumnPair w y x amount (n:ns) = do
--    putStrLn "displaying column pair..."
    s <- scale
    let y' = if amount < 3 then y + amount * s else y + (amount - 3) * s
    let x' = if amount < 3 then x else x + 2*s
    if n == '1' then displayLED w y' x' on
    else displayLED w y' x' off
    displayColumnPair w y x (amount + 1) ns

tick :: Window -> Int -> Int -> IO ()
tick w y x = do
--    putStrLn "ticking..."
    werase w
    s <- scale
    let y' = y `div` 2 - (3 * s) `div` 2
    let x' = x `div` 2 - 6 * s
--    let y' = 0
--    let x' = 0
    zonedTime <- getZonedTime
    let timeString = tail $ dropWhile(/= ' ') (show zonedTime)
        hour = read $ takeWhile(/= ':') timeString
        timeString' = tail $ dropWhile(/= ':') timeString
        minute = read $ takeWhile(/= ':') timeString'
        timeString'' = tail $ dropWhile(/= ':') timeString'
        second = read $ takeWhile(/= '.') timeString''
    wMove w y' x'
    --Draw hour
    let hourBinString = showIntAtBase 2 intToDigit hour ""
        hourBinStringFmt = (take (6 - (length hourBinString)) (repeat '0')) ++ hourBinString
--    putStrLn hourBinStringFmt
    displayColumnPair w y' x' 0 hourBinStringFmt
--    putStrLn "FINISHED HOUR"
    let minuteBinString = showIntAtBase 2 intToDigit minute ""
        minuteBinStringFmt = (take (6 - (length minuteBinString)) (repeat '0')) ++ minuteBinString
--    putStrLn minuteBinStringFmt
    displayColumnPair w y' (x' + 5 * s) 0 minuteBinStringFmt
--    putStrLn "FINISHED MINUTE"
    let secondBinString = showIntAtBase 2 intToDigit second ""
        secondBinStringFmt = (take (6 - (length secondBinString)) (repeat '0')) ++ secondBinString
--    putStrLn secondBinStringFmt
    displayColumnPair w y' (x' + 10 * s) 0 secondBinStringFmt
--    putStrLn "FINISHED SECOND"
    refresh
    update
    threadDelay 1000000
--    (ynew,xnew) <- resizeui
    (ynew,xnew) <- scrSize
    c <- getch 
    if c == (113) then return ()
    else tick w ynew xnew
--    else tick w ynew xnew 

resize :: IO ()
resize = do
    putStrLn "RESIZING"
    (y,x) <- resizeui
    resizeTerminal y x

cleanStop :: IO() 
cleanStop = do
    endWin
    exitImmediately ExitSuccess

main = do
    args <- getArgs
    initCurses
    initColors
    cursSet CursorInvisible
    echo False
    w <-initScr
    (y,x) <- scrSize
    cBreak True
    noDelay w True
    keypad w True
    let sigwinch = fromJust cursesSigWinch
    installHandler sigwinch (Catch resize) Nothing
    installHandler keyboardSignal (CatchOnce cleanStop) Nothing
    refresh
    update
    tick w y x
    putStrLn (show sigwinch)
    endWin