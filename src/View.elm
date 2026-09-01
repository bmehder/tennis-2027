module View exposing (view)

import Html exposing (Html, a, button, div, h1, img, span, sup, text)
import Html.Attributes exposing (alt, attribute, class, classList, href, rel, src, target)
import Html.Events exposing (onClick)
import TennisMatch exposing (CompletedMatch, CompletedSet(..), Game(..), Match(..), MatchInProgress, Player(..), PlayerNames, PointScore(..), SetScore, otherPlayer, tiebreakServer)



-- MATCH VIEW


type alias Events msg =
    { pointWon : Player -> msg
    , restartMatch : msg
    }


view : Events msg -> Match -> Html msg
view events matchState =
    case matchState of
        InProgress match ->
            viewInProgress events match

        Completed match ->
            viewCompleted events match


viewInProgress : Events msg -> MatchInProgress -> Html msg
viewInProgress events match =
    div [ class "app-shell" ]
        [ h1 [] [ text "Elm Tennis 2027" ]
        , div [ class "scoreboard" ]
            [ scoreboardHeader
            , inProgressPlayerRow match PlayerOne
            , inProgressPlayerRow match PlayerTwo
            , repositoryFooter
            ]
        , div [ class "point-controls" ]
            [ pointButton events PlayerOne match.players.playerOne
            , pointButton events PlayerTwo match.players.playerTwo
            ]
        ]


viewCompleted : Events msg -> CompletedMatch -> Html msg
viewCompleted events match =
    div [ class "app-shell" ]
        [ h1 [] [ text "Elm Tennis 2027" ]
        , div [ class "scoreboard" ]
            [ scoreboardHeader
            , completedPlayerRow match PlayerOne
            , completedPlayerRow match PlayerTwo
            , repositoryFooter
            ]
        , button
            [ class "restart-button"
            , onClick events.restartMatch
            ]
            [ text "Start a new match" ]
        ]



-- CONTROLS


pointButton : Events msg -> Player -> String -> Html msg
pointButton events player name =
    button
        [ class "point-button"
        , onClick (events.pointWon player)
        ]
        [ span [ class "button-label" ] [ text "Point for" ]
        , text name
        ]



-- SCOREBOARD


type alias PlayerRow =
    { namesAreEditable : Bool
    , players : PlayerNames
    , completedSets : List CompletedSet
    , currentSet : Maybe SetScore
    , currentGame : Maybe Game
    , currentServer : Maybe Player
    , player : Player
    }


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


inProgressPlayerRow : MatchInProgress -> Player -> Html msg
inProgressPlayerRow match player =
    playerRow
        { namesAreEditable = True
        , players = match.players
        , completedSets = match.completedSets
        , currentSet = Just match.currentSet.games
        , currentGame = Just match.currentSet.game
        , currentServer = Just (currentServer match.currentSet.game)
        , player = player
        }


completedPlayerRow : CompletedMatch -> Player -> Html msg
completedPlayerRow match player =
    playerRow
        { namesAreEditable = False
        , players = match.players
        , completedSets = match.sets
        , currentSet = Nothing
        , currentGame = Nothing
        , currentServer = Nothing
        , player = player
        }


playerRow : PlayerRow -> Html msg
playerRow row =
    let
        completedCells =
            List.map (completedSetCell row.player) row.completedSets

        currentCell =
            case row.currentSet of
                Just score ->
                    [ scoreCell False (scoreFor row.player score) [] ]

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
                , ( "is-serving", row.currentServer == Just row.player )
                ]
            ]
            []
         , playerNameView row.namesAreEditable row.players row.player
         ]
            ++ completedCells
            ++ currentCell
            ++ emptyCells
            ++ [ gameScoreCell row.player row.currentGame ]
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



-- SCORE CELLS


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



-- SCORE FORMATTING


scoreFor : Player -> { score | playerOne : Int, playerTwo : Int } -> Int
scoreFor player score =
    case player of
        PlayerOne ->
            score.playerOne

        PlayerTwo ->
            score.playerTwo


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



-- FOOTER


repositoryFooter : Html msg
repositoryFooter =
    div [ class "card-footer" ]
        [ a
            [ class "footer-link"
            , href "https://github.com/bmehder/tennis-2027/blob/main/elm-vs-typescript.md"
            , target "_blank"
            , rel "noopener noreferrer"
            ]
            [ text "Read the design article" ]
        , a
            [ class "footer-link"
            , href "https://github.com/bmehder/tennis-2027"
            , target "_blank"
            , rel "noopener noreferrer"
            ]
            [ img [ class "github-icon", src "/github.svg", alt "" ] []
            , text "View on GitHub"
            ]
        ]
