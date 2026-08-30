module TennisMatch exposing
    ( CompletedMatch
    , CompletedSet(..)
    , Game(..)
    , Match(..)
    , MatchInProgress
    , Msg(..)
    , Player(..)
    , PlayerNames
    , PointResult(..)
    , PointScore(..)
    , RegularGameState
    , SetInProgress
    , SetScore
    , TiebreakScore
    , TiebreakState
    , initialMatch
    , pointWon
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
    = GameContinues PointScore
    | GameWonBy Player


pointWon : Player -> PointScore -> PointResult
pointWon player score =
    case ( player, score ) of
        ( PlayerOne, LoveLove ) ->
            GameContinues FifteenLove

        ( PlayerTwo, LoveLove ) ->
            GameContinues LoveFifteen

        ( PlayerOne, FifteenLove ) ->
            GameContinues ThirtyLove

        ( PlayerTwo, FifteenLove ) ->
            GameContinues FifteenAll

        ( PlayerOne, LoveFifteen ) ->
            GameContinues FifteenAll

        ( PlayerTwo, LoveFifteen ) ->
            GameContinues LoveThirty

        ( PlayerOne, FifteenAll ) ->
            GameContinues ThirtyFifteen

        ( PlayerTwo, FifteenAll ) ->
            GameContinues FifteenThirty

        ( PlayerOne, ThirtyLove ) ->
            GameContinues FortyLove

        ( PlayerTwo, ThirtyLove ) ->
            GameContinues ThirtyFifteen

        ( PlayerOne, LoveThirty ) ->
            GameContinues FifteenThirty

        ( PlayerTwo, LoveThirty ) ->
            GameContinues LoveForty

        ( PlayerOne, ThirtyFifteen ) ->
            GameContinues FortyFifteen

        ( PlayerTwo, ThirtyFifteen ) ->
            GameContinues ThirtyAll

        ( PlayerOne, FifteenThirty ) ->
            GameContinues ThirtyAll

        ( PlayerTwo, FifteenThirty ) ->
            GameContinues FifteenForty

        ( PlayerOne, ThirtyAll ) ->
            GameContinues FortyThirty

        ( PlayerTwo, ThirtyAll ) ->
            GameContinues ThirtyForty

        ( PlayerOne, FortyLove ) ->
            GameWonBy PlayerOne

        ( PlayerTwo, FortyLove ) ->
            GameContinues FortyFifteen

        ( PlayerOne, LoveForty ) ->
            GameContinues FifteenForty

        ( PlayerTwo, LoveForty ) ->
            GameWonBy PlayerTwo

        ( PlayerOne, FortyFifteen ) ->
            GameWonBy PlayerOne

        ( PlayerTwo, FortyFifteen ) ->
            GameContinues FortyThirty

        ( PlayerOne, FifteenForty ) ->
            GameContinues ThirtyForty

        ( PlayerTwo, FifteenForty ) ->
            GameWonBy PlayerTwo

        ( PlayerOne, FortyThirty ) ->
            GameWonBy PlayerOne

        ( PlayerTwo, FortyThirty ) ->
            GameContinues Deuce

        ( PlayerOne, ThirtyForty ) ->
            GameContinues Deuce

        ( PlayerTwo, ThirtyForty ) ->
            GameWonBy PlayerTwo

        ( PlayerOne, Deuce ) ->
            GameContinues (Advantage PlayerOne)

        ( PlayerTwo, Deuce ) ->
            GameContinues (Advantage PlayerTwo)

        ( PlayerOne, Advantage PlayerOne ) ->
            GameWonBy PlayerOne

        ( PlayerTwo, Advantage PlayerOne ) ->
            GameContinues Deuce

        ( PlayerOne, Advantage PlayerTwo ) ->
            GameContinues Deuce

        ( PlayerTwo, Advantage PlayerTwo ) ->
            GameWonBy PlayerTwo


type Game
    = RegularGame RegularGameState
    | Tiebreak TiebreakState


type alias RegularGameState =
    { score : PointScore
    , server : Player
    }


type alias TiebreakState =
    { score : TiebreakScore
    , firstServer : Player
    }



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
