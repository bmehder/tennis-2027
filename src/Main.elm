module Main exposing (main)

import Browser
import Html exposing (Html, a, button, div, h1, img, span, sup, text)
import Html.Attributes exposing (alt, attribute, class, classList, href, rel, src, target)
import Html.Events exposing (onClick)
import TennisMatch exposing (CompletedMatch, CompletedSet(..), Game(..), GameResult(..), Match(..), MatchInProgress, Msg(..), Player(..), PlayerNames, PointScore(..), SetScore, TiebreakScore, initialMatch, gamePointWon, tiebreakServer)


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
                    updateInProgress player match

                Completed _ ->
                    model

        RestartMatch ->
            InProgress initialMatch

updateInProgress : Player -> MatchInProgress -> Match
updateInProgress player match =
    case gamePointWon player match.currentSet.game of
        GameContinues game ->
            InProgress (replaceCurrentGame game match)

        RegularGameWon winner ->
            case match.currentSet.game of
                RegularGame game ->
                    finishRegularGame winner game.server match

                Tiebreak _ ->
                    InProgress match

        TiebreakWon winner score ->
            case match.currentSet.game of
                Tiebreak tiebreak ->
                    finishTiebreak winner score tiebreak.firstServer match

                RegularGame _ ->
                    InProgress match


replaceCurrentGame : Game -> MatchInProgress -> MatchInProgress
replaceCurrentGame game match =
    let
        currentSet =
            match.currentSet
    in
    { match | currentSet = { currentSet | game = game } }


finishRegularGame : Player -> Player -> MatchInProgress -> Match
finishRegularGame winner server match =
    let
        currentSet =
            match.currentSet

        updatedGames =
            incrementSetScore winner currentSet.games

        nextServer =
            otherPlayer server
    in
    if setIsWonBy winner updatedGames then
        completeSet winner (RegularSet updatedGames) nextServer match

    else if updatedGames.playerOne == 6 && updatedGames.playerTwo == 6 then
        InProgress
            { match
                | currentSet =
                    { games = updatedGames
                    , game =
                        Tiebreak
                            { score = { playerOne = 0, playerTwo = 0 }
                            , firstServer = nextServer
                            }
                    }
            }

    else
        InProgress
            { match
                | currentSet =
                    { games = updatedGames
                    , game =
                        RegularGame
                            { score = LoveLove
                            , server = nextServer
                            }
                    }
            }


finishTiebreak : Player -> TiebreakScore -> Player -> MatchInProgress -> Match
finishTiebreak winner tiebreakScore firstServer match =
    let
        finalSetScore =
            incrementSetScore winner match.currentSet.games
    in
    completeSet
        winner
        (TiebreakSet finalSetScore tiebreakScore)
        (otherPlayer firstServer)
        match


incrementSetScore : Player -> SetScore -> SetScore
incrementSetScore player score =
    case player of
        PlayerOne ->
            { score | playerOne = score.playerOne + 1 }

        PlayerTwo ->
            { score | playerTwo = score.playerTwo + 1 }


setIsWonBy : Player -> SetScore -> Bool
setIsWonBy player score =
    let
        ( winnerGames, loserGames ) =
            case player of
                PlayerOne ->
                    ( score.playerOne, score.playerTwo )

                PlayerTwo ->
                    ( score.playerTwo, score.playerOne )
    in
    winnerGames >= 6 && winnerGames - loserGames >= 2


completeSet : Player -> CompletedSet -> Player -> MatchInProgress -> Match
completeSet winner completedSet nextServer match =
    let
        completedSets =
            match.completedSets ++ [ completedSet ]

        setsWon =
            List.length
                (List.filter
                    (\set -> completedSetWinner set == winner)
                    completedSets
                )
    in
    if setsWon == 2 then
        Completed
            { players = match.players
            , sets = completedSets
            }

    else
        InProgress
            { match
                | completedSets = completedSets
                , currentSet =
                    { games = { playerOne = 0, playerTwo = 0 }
                    , game =
                        RegularGame
                            { score = LoveLove
                            , server = nextServer
                            }
                    }
            }


completedSetWinner : CompletedSet -> Player
completedSetWinner completedSet =
    let
        score =
            case completedSet of
                RegularSet setScore ->
                    setScore

                TiebreakSet setScore _ ->
                    setScore
    in
    if score.playerOne > score.playerTwo then
        PlayerOne

    else
        PlayerTwo


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
    div [ class "app-shell" ]
        [ h1 [] [ text "Elm Tennis 2027" ]
        , div [ class "scoreboard" ]
            [ scoreboardHeader
            , playerRow
                True
                match.players
                match.completedSets
                (Just match.currentSet.games)
                (Just match.currentSet.game)
                (Just (currentServer match.currentSet.game))
                PlayerOne
            , playerRow
                True
                match.players
                match.completedSets
                (Just match.currentSet.games)
                (Just match.currentSet.game)
                (Just (currentServer match.currentSet.game))
                PlayerTwo
            , repositoryFooter
            ]
        , div [ class "point-controls" ]
            [ button
                [ class "point-button"
                , onClick (PointWonBy PlayerOne)
                ]
                [ span [ class "button-label" ] [ text "Point for" ]
                , text match.players.playerOne
                ]
            , button
                [ class "point-button"
                , onClick (PointWonBy PlayerTwo)
                ]
                [ span [ class "button-label" ] [ text "Point for" ]
                , text match.players.playerTwo
                ]
            ]
        ]


viewCompleted : CompletedMatch -> Html Msg
viewCompleted match =
    div [ class "app-shell" ]
        [ h1 [] [ text "Elm Tennis 2027" ]
        , div [ class "scoreboard" ]
            [ scoreboardHeader
            , playerRow False match.players match.sets Nothing Nothing Nothing PlayerOne
            , playerRow False match.players match.sets Nothing Nothing Nothing PlayerTwo
            , repositoryFooter
            ]
        , button
            [ class "restart-button"
            , onClick RestartMatch
            ]
            [ text "Start a new match" ]
        ]


repositoryFooter : Html msg
repositoryFooter =
    div [ class "card-footer" ]
        [ a
            [ class "github-link"
            , href "https://github.com/bmehder/tennis-2027"
            , target "_blank"
            , rel "noopener noreferrer"
            ]
            [ img
                [ class "github-icon"
                , src "/github.svg"
                , alt ""
                ]
                []
            , text "View on GitHub"
            ]
        ]


scoreboardHeader : Html msg
scoreboardHeader =
    div [ class "scoreboard-row scoreboard-header" ]
        [ span [] []
        , span [ class "player-heading" ] [ text "Player" ]
        , span [] [ text "1" ]
        , span [] [ text "2" ]
        , span [] [ text "3" ]
        , span [] [ text "Pts" ]
        ]


playerRow : Bool -> PlayerNames -> List CompletedSet -> Maybe SetScore -> Maybe Game -> Maybe Player -> Player -> Html msg
playerRow namesAreEditable players completedSets currentSet currentGame currentServer_ player =
    let
        completedCells =
            List.map (completedSetCell player) completedSets

        currentCell =
            case currentSet of
                Just score ->
                    [ scoreCell False (scoreFor player score) [] ]

                Nothing ->
                    []

        emptyCells =
            List.repeat (3 - List.length completedCells - List.length currentCell)
                (span [ class "set-score empty-score" ] [ text "–" ])
    in
    div [ class "scoreboard-row player-row" ]
        ([ span
            [ classList
                [ ( "serve-dot", True )
                , ( "is-serving", currentServer_ == Just player )
                ]
            ]
            []
         , playerNameView namesAreEditable players player
         ]
            ++ completedCells
            ++ currentCell
            ++ emptyCells
            ++ [ gameScoreCell player currentGame ]
        )


playerNameView : Bool -> PlayerNames -> Player -> Html msg
playerNameView isEditable players player =
    let
        editableAttributes =
            if isEditable then
                [ attribute "contenteditable" "true"
                , attribute "spellcheck" "false"
                ]

            else
                []
    in
    span
        (classList
            [ ( "player-name", True )
            , ( "is-editable", isEditable )
            ]
            :: editableAttributes
        )
        [ text (playerName players player) ]


completedSetCell : Player -> CompletedSet -> Html msg
completedSetCell player completedSet =
    case completedSet of
        RegularSet score ->
            scoreCell
                (scoreFor player score > scoreFor (otherPlayer player) score)
                (scoreFor player score)
                []

        TiebreakSet score tiebreakScore ->
            let
                playerLostSet =
                    scoreFor player score < scoreFor (otherPlayer player) score

                tiebreakDetail =
                    if playerLostSet then
                        [ sup [ class "tiebreak-score" ]
                            [ text (String.fromInt (scoreFor player tiebreakScore)) ]
                        ]

                    else
                        []
            in
            scoreCell (not playerLostSet) (scoreFor player score) tiebreakDetail


scoreCell : Bool -> Int -> List (Html msg) -> Html msg
scoreCell isSetWinner score detail =
    span
        [ classList
            [ ( "set-score", True )
            , ( "set-winner", isSetWinner )
            ]
        ]
        (text (String.fromInt score) :: detail)


scoreFor : Player -> { score | playerOne : Int, playerTwo : Int } -> Int
scoreFor player score =
    case player of
        PlayerOne ->
            score.playerOne

        PlayerTwo ->
            score.playerTwo


gameScoreCell : Player -> Maybe Game -> Html msg
gameScoreCell player game =
    let
        score =
            case game of
                Just (RegularGame state) ->
                    regularGameScoreFor player state.score

                Just (Tiebreak state) ->
                    String.fromInt (scoreFor player state.score)

                Nothing ->
                    "–"
    in
    span [ class "game-score" ] [ text score ]


regularGameScoreFor : Player -> PointScore -> String
regularGameScoreFor player score =
    let
        ( playerOneScore, playerTwoScore ) =
            regularGameScores score
    in
    case player of
        PlayerOne ->
            playerOneScore

        PlayerTwo ->
            playerTwoScore


regularGameScores : PointScore -> ( String, String )
regularGameScores score =
    case score of
        LoveLove ->
            ( "0", "0" )

        FifteenLove ->
            ( "15", "0" )

        LoveFifteen ->
            ( "0", "15" )

        FifteenAll ->
            ( "15", "15" )

        ThirtyLove ->
            ( "30", "0" )

        LoveThirty ->
            ( "0", "30" )

        ThirtyFifteen ->
            ( "30", "15" )

        FifteenThirty ->
            ( "15", "30" )

        ThirtyAll ->
            ( "30", "30" )

        FortyLove ->
            ( "40", "0" )

        LoveForty ->
            ( "0", "40" )

        FortyFifteen ->
            ( "40", "15" )

        FifteenForty ->
            ( "15", "40" )

        FortyThirty ->
            ( "40", "30" )

        ThirtyForty ->
            ( "30", "40" )

        Deuce ->
            ( "40", "40" )

        Advantage PlayerOne ->
            ( "Ad", "40" )

        Advantage PlayerTwo ->
            ( "40", "Ad" )


currentServer : Game -> Player
currentServer game =
    case game of
        RegularGame state ->
            state.server

        Tiebreak state ->
            tiebreakServer state


playerName : PlayerNames -> Player -> String
playerName players player =
    case player of
        PlayerOne ->
            players.playerOne

        PlayerTwo ->
            players.playerTwo
