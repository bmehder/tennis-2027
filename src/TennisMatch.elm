module TennisMatch exposing
    ( CompletedMatch
    , CompletedSet(..)
    , Game(..)
    , Match(..)
    , MatchInProgress
    , Player(..)
    , PlayerNames
    , PointScore(..)
    , RegularGameState
    , SetInProgress
    , SetScore
    , TiebreakScore
    , TiebreakState
    , initialMatch
    , otherPlayer
    , pointWon
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
    | RegularGameWon RegularGameWin
    | TiebreakWon TiebreakWin


type alias RegularGameWin =
    { winner : Player
    , server : Player
    }


type alias TiebreakWin =
    { winner : Player
    , score : TiebreakScore
    , firstServer : Player
    }


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
                    RegularGameWon
                        { winner = winner
                        , server = state.server
                        }

        Tiebreak state ->
            let
                score =
                    incrementTiebreakScore player state.score
            in
            if tiebreakIsWonBy player score then
                TiebreakWon
                    { winner = player
                    , score = score
                    , firstServer = state.firstServer
                    }

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

        -- The first server serves once. Service then alternates in pairs:
        -- other, other, first, first, other, other, and so on.
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


initialMatch : Match
initialMatch =
    InProgress
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


pointWon : Player -> Match -> Match
pointWon player matchState =
    case matchState of
        InProgress match ->
            updateInProgress player match

        Completed _ ->
            matchState


updateInProgress : Player -> MatchInProgress -> Match
updateInProgress player match =
    case gamePointWon player match.currentSet.game of
        GameContinues game ->
            InProgress (replaceCurrentGame game match)

        RegularGameWon result ->
            finishRegularGame result.winner result.server match

        TiebreakWon result ->
            finishTiebreak result.winner result.score result.firstServer match


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
