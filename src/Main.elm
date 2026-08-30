module Main exposing (main)

import Browser
import Html exposing (Html, button, div, h1, p, text)
import Html.Events exposing (onClick)
import TennisMatch exposing (CompletedMatch, Game(..), Match(..), MatchInProgress, Msg(..), Player(..), PlayerNames, PointResult(..), PointScore(..), initialMatch, pointWon)


type alias Model =
    Match


main : Program () Model Msg
main =
    Browser.sandbox
        { init =
            InProgress initialMatch
        , update = update
        , view = view
        }


update : Msg -> Model -> Model
update msg model =
    case msg of
        PointWonBy player ->
            case model of
                InProgress match ->
                    InProgress (updateInProgress player match)

                Completed _ ->
                    model

        RestartMatch ->
            InProgress initialMatch


updateInProgress : Player -> MatchInProgress -> MatchInProgress
updateInProgress player match =
    case match.currentSet.game of
        RegularGame game ->
            case pointWon player game.score of
                GameContinues score ->
                    let
                        currentSet =
                            match.currentSet

                        updatedSet =
                            { currentSet
                                | game = RegularGame { game | score = score }
                            }
                    in
                    { match | currentSet = updatedSet }

                GameWonBy winner ->
                    finishGame winner game.server match

        Tiebreak _ ->
            match


finishGame : Player -> Player -> MatchInProgress -> MatchInProgress
finishGame winner server match =
    let
        currentSet =
            match.currentSet

        games =
            currentSet.games

        updatedGames =
            case winner of
                PlayerOne ->
                    { games | playerOne = games.playerOne + 1 }

                PlayerTwo ->
                    { games | playerTwo = games.playerTwo + 1 }

        nextGame =
            RegularGame
                { score = LoveLove
                , server = otherPlayer server
                }

        updatedSet =
            { currentSet
                | games = updatedGames
                , game = nextGame
            }
    in
    { match | currentSet = updatedSet }


otherPlayer : Player -> Player
otherPlayer player =
    case player of
        PlayerOne ->
            PlayerTwo

        PlayerTwo ->
            PlayerOne



-- VIEW


view : Model -> Html Msg
view model =
    case model of
        InProgress match ->
            viewInProgress match

        Completed match ->
            viewCompleted match


viewInProgress : MatchInProgress -> Html Msg
viewInProgress match =
    div []
        [ h1 [] [ text "Tennis Match" ]
        , p []
            [ text
                (match.players.playerOne
                    ++ "  "
                    ++ String.fromInt match.currentSet.games.playerOne
                )
            ]
        , p []
            [ text
                (match.players.playerTwo
                    ++ "  "
                    ++ String.fromInt match.currentSet.games.playerTwo
                )
            ]
        , p [] [ text (gameScoreLabel match.currentSet.game) ]
        , p [] [ text (serverLabel match.players match.currentSet.game) ]
        , button
            [ onClick (PointWonBy PlayerOne)
            ]
            [ text ("Point for " ++ match.players.playerOne) ]
        , button
            [ onClick (PointWonBy PlayerTwo)
            ]
            [ text ("Point for " ++ match.players.playerTwo) ]
        ]


viewCompleted : CompletedMatch -> Html Msg
viewCompleted match =
    div []
        [ h1 [] [ text "Match complete" ]
        , p [] [ text match.players.playerOne ]
        , p [] [ text match.players.playerTwo ]
        ]


serverLabel : PlayerNames -> Game -> String
serverLabel players game =
    case game of
        RegularGame state ->
            playerName players state.server ++ " is serving"

        Tiebreak _ ->
            "Tiebreak"


playerName : PlayerNames -> Player -> String
playerName players player =
    case player of
        PlayerOne ->
            players.playerOne

        PlayerTwo ->
            players.playerTwo


gameScoreLabel : Game -> String
gameScoreLabel game =
    case game of
        RegularGame state ->
            pointScoreLabel state.score

        Tiebreak state ->
            String.fromInt state.score.playerOne
                ++ "–"
                ++ String.fromInt state.score.playerTwo


pointScoreLabel : PointScore -> String
pointScoreLabel score =
    case score of
        LoveLove ->
            "Love–Love"

        FifteenLove ->
            "15–Love"

        LoveFifteen ->
            "Love–15"

        FifteenAll ->
            "15–15"

        ThirtyLove ->
            "30–Love"

        LoveThirty ->
            "Love–30"

        ThirtyFifteen ->
            "30–15"

        FifteenThirty ->
            "15–30"

        ThirtyAll ->
            "30–30"

        FortyLove ->
            "40–Love"

        LoveForty ->
            "Love–40"

        FortyFifteen ->
            "40–15"

        FifteenForty ->
            "15–40"

        FortyThirty ->
            "40–30"

        ThirtyForty ->
            "30–40"

        Deuce ->
            "Deuce"

        Advantage PlayerOne ->
            "Advantage Player One"

        Advantage PlayerTwo ->
            "Advantage Player Two"
