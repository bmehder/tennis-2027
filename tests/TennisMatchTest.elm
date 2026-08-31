module TennisMatchTest exposing (suite)

import Expect
import TennisMatch exposing (CompletedSet(..), Game(..), Match(..), Player(..), PointScore(..), initialMatch, pointWon, tiebreakServer)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "a best-of-three tennis match"
        [ test "four points win a game and rotate the server" <|
            \_ ->
                initialState
                    |> winGame PlayerOne
                    |> Expect.equal
                        (InProgress
                            { players = defaultPlayers
                            , completedSets = []
                            , currentSet =
                                    { games = { playerOne = 1, playerTwo = 0 }
                                    , game =
                                        RegularGame
                                            { score = LoveLove
                                            , server = PlayerTwo
                                            }
                                    }
                            }
                        )
        , test "deuce and advantage require a two-point lead" <|
            \_ ->
                initialState
                    |> winPoints
                        [ PlayerOne
                        , PlayerOne
                        , PlayerOne
                        , PlayerTwo
                        , PlayerTwo
                        , PlayerTwo
                        , PlayerOne
                        , PlayerTwo
                        , PlayerTwo
                        , PlayerTwo
                        ]
                    |> Expect.equal
                        (InProgress
                            { players = defaultPlayers
                            , completedSets = []
                            , currentSet =
                                { games = { playerOne = 0, playerTwo = 1 }
                                , game =
                                    RegularGame
                                        { score = LoveLove
                                        , server = PlayerTwo
                                        }
                                }
                            }
                        )
        , test "a set continues into a tiebreak at six games all" <|
            \_ ->
                initialState
                    |> winGames (List.repeat 6 [ PlayerOne, PlayerTwo ] |> List.concat)
                    |> Expect.equal
                        (InProgress
                            { players = defaultPlayers
                            , completedSets = []
                            , currentSet =
                                    { games = { playerOne = 6, playerTwo = 6 }
                                    , game =
                                        Tiebreak
                                            { score = { playerOne = 0, playerTwo = 0 }
                                            , firstServer = PlayerOne
                                            }
                                    }
                            }
                        )
        , test "winning the tiebreak records its score and starts a new set" <|
            \_ ->
                initialState
                    |> winGames (List.repeat 6 [ PlayerOne, PlayerTwo ] |> List.concat)
                    |> winPoints (List.repeat 7 PlayerOne)
                    |> Expect.equal
                        (InProgress
                            { players = defaultPlayers
                            , completedSets =
                                    [ TiebreakSet
                                        { playerOne = 7, playerTwo = 6 }
                                        { playerOne = 7, playerTwo = 0 }
                                    ]
                                , currentSet =
                                    { games = { playerOne = 0, playerTwo = 0 }
                                    , game =
                                        RegularGame
                                            { score = LoveLove
                                            , server = PlayerTwo
                                            }
                                    }
                            }
                        )
        , test "a tiebreak requires a two-point lead" <|
            \_ ->
                initialState
                    |> winGames (List.repeat 6 [ PlayerOne, PlayerTwo ] |> List.concat)
                    |> winPoints (List.repeat 6 [ PlayerOne, PlayerTwo ] |> List.concat)
                    |> winPoints [ PlayerOne, PlayerOne ]
                    |> Expect.equal
                        (InProgress
                            { players = defaultPlayers
                            , completedSets =
                                [ TiebreakSet
                                    { playerOne = 7, playerTwo = 6 }
                                    { playerOne = 8, playerTwo = 6 }
                                ]
                            , currentSet =
                                { games = { playerOne = 0, playerTwo = 0 }
                                , game =
                                    RegularGame
                                        { score = LoveLove
                                        , server = PlayerTwo
                                        }
                                }
                            }
                        )
        , test "tiebreak service alternates once and then in pairs" <|
            \_ ->
                [ { playerOne = 0, playerTwo = 0 }
                , { playerOne = 1, playerTwo = 0 }
                , { playerOne = 1, playerTwo = 1 }
                , { playerOne = 2, playerTwo = 1 }
                , { playerOne = 2, playerTwo = 2 }
                , { playerOne = 3, playerTwo = 2 }
                , { playerOne = 3, playerTwo = 3 }
                ]
                    |> List.map
                        (\score ->
                            tiebreakServer
                                { score = score
                                , firstServer = PlayerOne
                                }
                        )
                    |> Expect.equal
                        [ PlayerOne
                        , PlayerTwo
                        , PlayerTwo
                        , PlayerOne
                        , PlayerOne
                        , PlayerTwo
                        , PlayerTwo
                        ]
        , test "winning two sets completes the match" <|
            \_ ->
                initialState
                    |> winGames (List.repeat 12 PlayerOne)
                    |> Expect.equal
                        (Completed
                            { players = defaultPlayers
                            , sets =
                                [ RegularSet { playerOne = 6, playerTwo = 0 }
                                , RegularSet { playerOne = 6, playerTwo = 0 }
                                ]
                            }
                        )
        ]


initialState : Match
initialState =
    initialMatch


defaultPlayers : TennisMatch.PlayerNames
defaultPlayers =
    { playerOne = "Player One"
    , playerTwo = "Player Two"
    }


winGame : Player -> Match -> Match
winGame player =
    winPoints (List.repeat 4 player)


winGames : List Player -> Match -> Match
winGames players match =
    List.foldl winGame match players


winPoints : List Player -> Match -> Match
winPoints players match =
    List.foldl pointWon match players
