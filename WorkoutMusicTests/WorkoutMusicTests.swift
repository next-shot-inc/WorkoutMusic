//
//  WorkoutMusicTests.swift
//  WorkoutMusicTests
//
//  Created by next-shot on 1/18/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import XCTest
@testable import WorkoutMusic

class WorkoutMusicTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPlayListDecodingSimpleStart() {
        let jsonString = """
        {
           "meta" :     {
               "results" :         {
                   "order" :             [
                       "playlists"
                   ]
               }
           }
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let json = try? JSONSerialization.jsonObject(with: jsonData, options: [])

        if let response = json as? [String: Any] {
            XCTAssertEqual(response.count, 1)
        }
    }
    
    func testPlayListDecodingSimple() {
        let jsonString = """
        {
           "meta" :     {
               "results" :         {
                   "order" :             [
                       "playlists"
                   ]
               }
           },
           "results" :     {
               "playlists" :         {
                   "data" :   [
                       {
                         "attributes" :     {
                               "artwork" :   {
                                   "url" : "https://is2-ssl.mzstatic.com/image/thumb/Features128/v4/ad/ea/9e/adea9e13-8b16-4410-ff1c-2df0fc2e657f/source/{w}x{h}cc.jpeg",
                                   "width" : 4320
                               },
                               "name" : "Pure Workout",
                               "url" : "https://music.apple.com/us/playlist/pure-workout/pl.ad0ee1557e3e4feba314fd70f7982766",
                               "description" : {
                                 "standard" : "If better fitness is your goal for 2020, start here. Katie Crewe.",
                                 "short" : "Canadian wellness expert Katie Crewe delivers calorie-burning tunes."
                               },
                          },
                          "href" : "/v1/catalog/us/playlists/pl.ad0ee1557e3e4feba314fd70f7982766",
                           "id" : "pl.ad0ee1557e3e4feba314fd70f7982766",
                        }
                    ],
                    "href" : "/v1/catalog/us/search?limit=25&term=workouts&types=playlists",
                    "next" : "/v1/catalog/us/search?offset=25&term=workouts&types=playlists"
              }
           }
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let json = try? JSONSerialization.jsonObject(with: jsonData, options: [])

        if let response = json as? [String: Any] {
            if let results = response["results"] as? [String:Any] {
                let playlists = results["playlists"] as? [String:Any]
                XCTAssertNotNil(playlists)
                let datas = playlists!["data"] as? [[String:Any]]
                XCTAssertNotNil(datas)
                let attributes = datas![0]["attributes"] as? [String:Any]
                XCTAssertNotNil(attributes)
                let artwork = attributes!["artwork"] as? [String:Any]
                let url = attributes!["url"] as? String
                let name = attributes!["name"] as? String
                let description = attributes!["description"] as? [String:Any]
                XCTAssertNotNil(description)
                let shortDescription = description!["short"] as? String
            }
        }
    }
    
    func testPlayListDecoding() {
        let jsonString = """
        {
          "meta" : {
            "results" : {
              "order" : [
                "playlists"
              ]
            }
          },
          "results" : {
            "playlists" : {
              "data" : [
                {
                  "id" : "pl.ad0ee1557e3e4feba314fd70f7982766",
                  "type" : "playlists",
                  "href" : "/v1/catalog/us/playlists/pl.ad0ee1557e3e4feba314fd70f7982766",
                  "attributes" : {
                    "name" : "Pure Workout",
                    "isChart" : false,
                    "playlistType" : "editorial",
                    "curatorName" : "Apple Music Pop",
                    "lastModifiedDate" : "2020-01-16T00:26:24Z",
                    "description" : {
                      "standard" : "If better fitness is your goal for 2020, start here. Katie Crewe isn’t just one of Canada’s most sought-after wellness experts, she’s also a featured trainer on the online training app Fitplan. \"Good music makes me feel energized and excited to train,” she tells Apple Music. Taking the reins (or should we say battle ropes?) for this week’s edition of our Pure Workout playlist, Crewe assembled a set of high-intensity tunes—from Buns of Steel-era classics to more modern dance-floor fare—to keep your metabolism burning hot. \"My workout playlist is often responsible for getting my butt out the door and to the gym,\" she adds. \"I hope this motivates you to get moving!” We regularly add new tracks to this collection. If you like something, add it to your library.",
                      "short" : "Canadian wellness expert Katie Crewe delivers calorie-burning tunes."
                    },
                    "playParams" : {
                      "id" : "pl.ad0ee1557e3e4feba314fd70f7982766",
                      "kind" : "playlist"
                    },
                    "artwork" : {
                      "height" : 1080,
                      "textColor3" : "43312e",
                      "textColor4" : "42333b",
                      "textColor2" : "15020f",
                      "width" : 4320,
                      "textColor1" : "160000",
                      "bgColor" : "f5f5e8",
                      "url" : "https://is2-ssl.mzstatic.com/image/thumb/Features128/v4/ad/ea/9e/adea9e13-8b16-4410-ff1c-2df0fc2e657f/source/{w}x{h}cc.jpeg"
                    },
                    "url" : "https://music.apple.com/us/playlist/pure-workout/pl.ad0ee1557e3e4feba314fd70f7982766"
                  }
                },
                {
                  "id" : "pl.4c62f568a0d64293a9c362037175c09b",
                  "type" : "playlists",
                  "href" : "/v1/catalog/us/playlists/pl.4c62f568a0d64293a9c362037175c09b",
                  "attributes" : {
                    "name" : "Hip-Hop Workout",
                    "isChart" : false,
                    "playlistType" : "editorial",
                    "curatorName" : "Apple Music Hip-Hop",
                    "lastModifiedDate" : "2020-01-17T05:00:02Z",
                    "description" : {
                      "standard" : "“This playlist is all about getting pumped up,” Bianca Andreescu tells Apple Music. For the 19-year-old US and Canadian Open defending champion, besting someone like Serena Williams takes a whole lot of a lot of things—patience, talent, dedication, skill, ambition, and guts. The Mississauga, Ontario-born tennis superstar also attributes some of her success to a killer set of pre-match tunes, which she’s shared with us for this edition of Hip-Hop Workout. “I’m a big fan of hip-hop and rap music because the songs are so motivating and put me in the right mindset,” she says. “I sort of get an adrenaline rush when I listen to it, which helps a lot on court. These artists are so talented, from their lyrics to the beats, and their passion for what they do is incredible and inspiring.” A recent knee injury might’ve sidelined Andreescu for the upcoming Australian Open, but these tracks—from artists like fellow Toronto-area heroes Drake, Tory Lanez, and The Weeknd and the recently departed Nipsey Hussle and Juice WRLD—will be just as much the soundtrack to her triumphant return as the perfect set for your next workout. We constantly update this playlist with new tunes to keep you pushing forward. If you like something, add it to your library.",
                      "short" : "Tennis phenom Bianca Andreescu shares the tunes that get her pumped."
                    },
                    "playParams" : {
                      "id" : "pl.4c62f568a0d64293a9c362037175c09b",
                      "kind" : "playlist"
                    },
                    "artwork" : {
                      "height" : 1080,
                      "textColor3" : "e2c9c8",
                      "textColor4" : "e2bca6",
                      "textColor2" : "f7e6cb",
                      "width" : 4320,
                      "textColor1" : "f7f6f4",
                      "bgColor" : "8e1414",
                      "url" : "https://is1-ssl.mzstatic.com/image/thumb/Features62/v4/5a/b3/31/5ab331e5-6024-dd6a-e988-43f7b46cd68c/source/{w}x{h}cc.jpeg"
                    },
                    "url" : "https://music.apple.com/us/playlist/hip-hop-workout/pl.4c62f568a0d64293a9c362037175c09b"
                  }
                },
                {
                  "id" : "pl.ae7c5093e09e49bcb60ec2a1fa2eec24",
                  "type" : "playlists",
                  "href" : "/v1/catalog/us/playlists/pl.ae7c5093e09e49bcb60ec2a1fa2eec24",
                  "attributes" : {
                    "name" : "Gymflow",
                    "isChart" : false,
                    "playlistType" : "editorial",
                    "curatorName" : "Apple Music Hip-Hop",
                    "lastModifiedDate" : "2020-01-17T06:25:46Z",
                    "description" : {
                      "standard" : "Sometimes the right playlist is the difference between a good workout and a great one. This mix, focusing on new hip-hop, is designed to keep you in beast mode, from warm-up to cooldown. Our editors regularly update these tracks, so if something gives you that extra push, add it to your library.",
                      "short" : "Hip-hop to get your heart pumping."
                    },
                    "playParams" : {
                      "id" : "pl.ae7c5093e09e49bcb60ec2a1fa2eec24",
                      "kind" : "playlist"
                    },
                    "artwork" : {
                      "height" : 1080,
                      "textColor3" : "d2deea",
                      "textColor4" : "caa990",
                      "textColor2" : "f4bc8e",
                      "width" : 4320,
                      "textColor1" : "ffffff",
                      "bgColor" : "205a99",
                      "url" : "https://is5-ssl.mzstatic.com/image/thumb/Features114/v4/f7/d8/29/f7d829dd-f9bc-d0b2-c6c6-b2b04d49c00a/source/{w}x{h}cc.jpeg"
                    },
                    "url" : "https://music.apple.com/us/playlist/gymflow/pl.ae7c5093e09e49bcb60ec2a1fa2eec24"
                  }
                }
              ],
              "href" : "/v1/catalog/us/search?limit=3&term=workouts&types=playlists",
              "next" : "/v1/catalog/us/search?offset=3&term=workouts&types=playlists"
            }
          }
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let json = try? JSONSerialization.jsonObject(with: jsonData, options: [])

        let response = json as? [String: Any]
        XCTAssertNotNil(response)
        let results = response!["results"] as? [String:Playlists]
        print(results)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
