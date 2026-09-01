module Main exposing (main)

import Browser
import Html exposing (Html)
import TennisMatch exposing (Match, Player, initialMatch, pointWon)
import View


type alias Model =
    Match


type Msg
    = PointWonBy Player
    | RestartMatch


main : Program () Model Msg
main =
    Browser.sandbox
        { init = initialMatch
        , update = update
        , view = view
        }


update : Msg -> Model -> Model
update msg model =
    case msg of
        PointWonBy pointWinner ->
            pointWon pointWinner model

        RestartMatch ->
            initialMatch


view : Model -> Html Msg
view =
    View.view
        { pointWon = PointWonBy
        , restartMatch = RestartMatch
        }
