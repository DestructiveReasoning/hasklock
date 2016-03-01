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

led = convertAttributes[Reverse]

initColors colorOn colorOff = do
    initPair (Pair 1) (Color colorOn) defaultBackground
    initPair (Pair 2) (Color colorOff) defaultBackground

on = Pair 1
off = Pair 2

findArgs :: Eq a => a -> [a] -> Int
findArgs x ls = length $ takeWhile (/= x) ls

scale :: IO Int
scale = do
    args <- getArgs
    if (length args) == 0 then return 4
    else do
        let sizeArg = (findArgs "-s" args) 
        if sizeArg >= (length args) then return 4
        else return (read $ args !! (sizeArg + 1)) 

displayLED w y x color = do
--    putStrLn "illuminating LED"
    wAttrSet w (led, color)
    s <- scale
    draw (s `div` 2) s
    where draw 0 _ = return()
          draw i s = do
                  mvWAddStr w (y + i) x (take(s) (repeat ' '))
                  draw (i - 1) s

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
    if (findArgs "-h" args) < (length args) 
    then do
        putStrLn "USAGE: hasklock [option] <value (if applicable)>"
        putStrLn "\nOPTIONS"
        putStrLn "-s [number]:  Sets the size of the clock. Default is 4, minimum is 2."
        putStrLn "-f [number]:  Sets the foreground color. Default is 60, range 0-256."
        putStrLn "-b [number]:  Sets the background color. Default is 233, range 0-256."
        putStrLn "-h:           Displays this message."
    else do
        initCurses
        if (length args) < 1 then initColors 60 233
        else do
            let onArg = findArgs "-f" args
                offArg = findArgs "-b" args
            if onArg >= (length args) then
                if offArg >= (length args)  then initColors 60 233
                else initColors 60 (read (args !! (offArg + 1)))  
            else if offArg >= (length args)  then initColors (read (args !! (onArg + 1))) 233
            else initColors (read (args !! (onArg + 1))) (read (args !! (offArg + 1)))
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
