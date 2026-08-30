module TennisMatch exposing
    ( CompletedMatch
    , CompletedSet(..)
    , Game(..)
    , GameResult(..)
    , Match(..)
    , MatchInProgress
    , Msg(..)
    , Player(..)
    , PlayerNames
    , PointScore(..)
    , RegularGameState
    , SetInProgress
    , SetScore
    , TiebreakScore
    , TiebreakState
    , initialMatch
    , gamePointWon
    , tiebreakServer
    )

{-| Domain sketch for a best-of-three match.

Each set plays a seven-point tiebreak at 6-6. Player One serves first in the
match.

-}

-- PARTICIPANTS


type Player
    = PlayerOne
    | PlayerTwo


type alias PlayerNames =
    { playerOne : String
    , playerTwo : String
    }



-- GAME


type PointScore
    = LoveLove
    | FifteenLove
    | LoveFifteen
    | FifteenAll
    | ThirtyLove
    | LoveThirty
    | ThirtyFifteen
    | FifteenThirty
    | ThirtyAll
    | FortyLove
    | LoveForty
    | FortyFifteen
    | FifteenForty
    | FortyThirty
    | ThirtyForty
    | Deuce
    | Advantage Player


type PointResult
    = PointScoreChanged PointScore
    | RegularGameWonBy Player


regularGamePointWon : Player -> PointScore -> PointResult
regularGamePointWon player score =
    case ( player, score ) of
        ( PlayerOne, LoveLove ) ->
            PointScoreChanged FifteenLove

        ( PlayerTwo, LoveLove ) ->
            PointScoreChanged LoveFifteen

        ( PlayerOne, FifteenLove ) ->
            PointScoreChanged ThirtyLove

        ( PlayerTwo, FifteenLove ) ->
            PointScoreChanged FifteenAll

        ( PlayerOne, LoveFifteen ) ->
            PointScoreChanged FifteenAll

        ( PlayerTwo, LoveFifteen ) ->
            PointScoreChanged LoveThirty

        ( PlayerOne, FifteenAll ) ->
            PointScoreChanged ThirtyFifteen

        ( PlayerTwo, FifteenAll ) ->
            PointScoreChanged FifteenThirty

        ( PlayerOne, ThirtyLove ) ->
            PointScoreChanged FortyLove

        ( PlayerTwo, ThirtyLove ) ->
            PointScoreChanged ThirtyFifteen

        ( PlayerOne, LoveThirty ) ->
            PointScoreChanged FifteenThirty

        ( PlayerTwo, LoveThirty ) ->
            PointScoreChanged LoveForty

        ( PlayerOne, ThirtyFifteen ) ->
            PointScoreChanged FortyFifteen

        ( PlayerTwo, ThirtyFifteen ) ->
            PointScoreChanged ThirtyAll

        ( PlayerOne, FifteenThirty ) ->
            PointScoreChanged ThirtyAll

        ( PlayerTwo, FifteenThirty ) ->
            PointScoreChanged FifteenForty

        ( PlayerOne, ThirtyAll ) ->
            PointScoreChanged FortyThirty

        ( PlayerTwo, ThirtyAll ) ->
            PointScoreChanged ThirtyForty

        ( PlayerOne, FortyLove ) ->
            RegularGameWonBy PlayerOne

        ( PlayerTwo, FortyLove ) ->
            PointScoreChanged FortyFifteen

        ( PlayerOne, LoveForty ) ->
            PointScoreChanged FifteenForty

        ( PlayerTwo, LoveForty ) ->
            RegularGameWonBy PlayerTwo

        ( PlayerOne, FortyFifteen ) ->
            RegularGameWonBy PlayerOne

        ( PlayerTwo, FortyFifteen ) ->
            PointScoreChanged FortyThirty

        ( PlayerOne, FifteenForty ) ->
            PointScoreChanged ThirtyForty

        ( PlayerTwo, FifteenForty ) ->
            RegularGameWonBy PlayerTwo

        ( PlayerOne, FortyThirty ) ->
            RegularGameWonBy PlayerOne

        ( PlayerTwo, FortyThirty ) ->
            PointScoreChanged Deuce

        ( PlayerOne, ThirtyForty ) ->
            PointScoreChanged Deuce

        ( PlayerTwo, ThirtyForty ) ->
            RegularGameWonBy PlayerTwo

        ( PlayerOne, Deuce ) ->
            PointScoreChanged (Advantage PlayerOne)

        ( PlayerTwo, Deuce ) ->
            PointScoreChanged (Advantage PlayerTwo)

        ( PlayerOne, Advantage PlayerOne ) ->
            RegularGameWonBy PlayerOne

        ( PlayerTwo, Advantage PlayerOne ) ->
            PointScoreChanged Deuce

        ( PlayerOne, Advantage PlayerTwo ) ->
            PointScoreChanged Deuce

        ( PlayerTwo, Advantage PlayerTwo ) ->
            RegularGameWonBy PlayerTwo


type Game
    = RegularGame RegularGameState
    | Tiebreak TiebreakState


type GameResult
    = GameContinues Game
    | RegularGameWon Player
    | TiebreakWon Player TiebreakScore


type alias RegularGameState =
    { score : PointScore
    , server : Player
    }


type alias TiebreakState =
    { score : TiebreakScore
    , firstServer : Player
    }


gamePointWon : Player -> Game -> GameResult
gamePointWon player game =
    case game of
        RegularGame state ->
            case regularGamePointWon player state.score of
                PointScoreChanged score ->
                    GameContinues (RegularGame { state | score = score })

                RegularGameWonBy winner ->
                    RegularGameWon winner

        Tiebreak state ->
            let
                score =
                    incrementTiebreakScore player state.score
            in
            if tiebreakIsWonBy player score then
                TiebreakWon player score

            else
                GameContinues (Tiebreak { state | score = score })


incrementTiebreakScore : Player -> TiebreakScore -> TiebreakScore
incrementTiebreakScore player score =
    case player of
        PlayerOne ->
            { score | playerOne = score.playerOne + 1 }

        PlayerTwo ->
            { score | playerTwo = score.playerTwo + 1 }


tiebreakIsWonBy : Player -> TiebreakScore -> Bool
tiebreakIsWonBy player score =
    let
        ( winnerPoints, loserPoints ) =
            case player of
                PlayerOne ->
                    ( score.playerOne, score.playerTwo )

                PlayerTwo ->
                    ( score.playerTwo, score.playerOne )
    in
    winnerPoints >= 7 && winnerPoints - loserPoints >= 2


tiebreakServer : TiebreakState -> Player
tiebreakServer state =
    let
        pointsPlayed =
            state.score.playerOne + state.score.playerTwo

        serviceTurn =
            (pointsPlayed + 1) // 2
    in
    if pointsPlayed == 0 || modBy 2 serviceTurn == 0 then
        state.firstServer

    else
        otherPlayer state.firstServer


otherPlayer : Player -> Player
otherPlayer player =
    case player of
        PlayerOne ->
            PlayerTwo

        PlayerTwo ->
            PlayerOne



-- SET


type alias SetInProgress =
    { games : SetScore
    , game : Game
    }


type CompletedSet
    = RegularSet SetScore
    | TiebreakSet SetScore TiebreakScore


type alias SetScore =
    { playerOne : Int
    , playerTwo : Int
    }


type alias TiebreakScore =
    { playerOne : Int
    , playerTwo : Int
    }



-- MATCH


type Match
    = InProgress MatchInProgress
    | Completed CompletedMatch


type alias MatchInProgress =
    { players : PlayerNames
    , completedSets : List CompletedSet
    , currentSet : SetInProgress
    }


type alias CompletedMatch =
    { players : PlayerNames
    , sets : List CompletedSet
    }


initialMatch : MatchInProgress
initialMatch =
    { players =
        { playerOne = "Player One"
        , playerTwo = "Player Two"
        }
    , completedSets = []
    , currentSet =
        { games =
            { playerOne = 0
            , playerTwo = 0
            }
        , game =
            RegularGame
                { score = LoveLove
                , server = PlayerOne
                }
        }
    }



-- APPLICATION


type Msg
    = PointWonBy Player
    | RestartMatch
