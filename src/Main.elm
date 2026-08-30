module Main exposing (main)

import Html exposing (Html, text)
import TennisMatch exposing (Player(..))


main : Html msg
main =
    text (playerLabel PlayerOne ++ " serves first")


playerLabel : Player -> String
playerLabel player =
    case player of
        PlayerOne ->
            "Player One"

        PlayerTwo ->
            "Player Two"