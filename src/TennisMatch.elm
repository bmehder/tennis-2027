module TennisMatch exposing
    ( CompletedMatch
    , CompletedSet(..)
    , Game(..)
    , Match(..)
    , MatchInProgress
    , Msg(..)
    , Player(..)
    , Players
    , PointScore(..)
    , RegularGameState
    , SetInProgress
    , SetScore
    , TiebreakScore
    , TiebreakState
    )

{-| Domain sketch for a best-of-three match.

Each set plays a seven-point tiebreak at 6-6. Player One serves first in the
match.

-}

-- PARTICIPANTS


type Player
    = PlayerOne
    | PlayerTwo


type alias Players =
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
    { players : Players
    , completedSets : List CompletedSet
    , currentSet : SetInProgress
    }


type alias CompletedMatch =
    { players : Players
    , sets : List CompletedSet
    }



-- APPLICATION


type Msg
    = PointWonBy Player
    | RestartMatch
