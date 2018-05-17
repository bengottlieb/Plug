//
//  AppDelegate.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import UIKit
import Plug

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
//	let pendingData = IncomingData(url: URL(string: "http://stackoverflow.com/questions/34182482/nsurlsessiondatadelegate-not-called")!)

//	let incoming = Incoming<Data>(url: URL(string: "http://stackoverflow.com/questions/34182482/nsurlsessiondatadelegate-not-called")!) { data in
//		print("Data: \(data)")
//		return data.data
//	}

	func testLargeDownloads() {
		let largeURL = URL(string: "https://dl.dropboxusercontent.com/u/85235/Stereotypies%20Therapy.mp4")!
		Plug.instance.timeout = 5.0
		
		let d1: JSONDictionary = ["h": "y"]
		let d2: JSONDictionary = ["h": "y"]
		
		print(d1 == d2)
		
		
		let connection = Plug.request(method: .GET, url: largeURL).completion { request, data in
			print("Completed")
		}.error { request, error in
			print("Failed with error: \(error)")
		}.progress {conn, percent in
			print("Completed \(percent * 100.0)%")
		}
		
		connection.start()
	}

	func testBodyPOST() {
		let url = "http://posttestserver.com/post.php"
		let payloadDict = ["embedded": "data goes here", "Test": "Field 1" ]
		
		let params = Plug.Parameters.body(payloadDict)
		
		Plug.request(method: .POST, url: url, parameters: params).completion { request, data in
			print("Request: \(request)")
		}.error { request, error in
				
		}.start()
	}
	
	func testSmallDownloads() {
		let smallURL = URL(string: "http://stackoverflow.com/questions/34182482/nsurlsessiondatadelegate-not-called")!
		
		
		let connection = Plug.request(method: .GET, url: smallURL).completion { request, data in
			print("Completed, got \(data.length) bytes")
			}.error { request, error in
				print("Failed with error: \(error)")
		} 
		
		connection.start()
	}
	
	func testMimeUpload() {
		let fileURL = Bundle.main.url(forResource: "sample_image", withExtension: "png")
		let url = "http://posttestserver.com/post.php"
		let payloadDict = ["Sample_Item": ["embedded": "data goes here", "Test": "Field 1", "one-level-more": ["name": "Bonzai", "career": "Buckaroo"]]]
		
		let components = Plug.FormComponents(fields: payloadDict)
		components.addFile(url: fileURL, name: "test file", mimeType: "image/png")
		
		let payload = Plug.Parameters.form(components)
		
		
		
		Plug.request(method: .POST, url: url, parameters: payload).completion { request, data in
			print("Request: \(request)")
		}.error { request, error in
				
		}.start()
	}
	
	func testJSONDownload() {
		let url = "http://jsonview.com/example.json"
		
		Connection(url: url)?.fetchJSON().then { json in
			let string = json.toString() ?? "unable to convert"
			print("Converted: \(string)")
			//let converted = JSONDictionary.fromString(string)
		//	converted!.log()
		}
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		Plug.instance.setup()
		
		//testBulkDownload()
		//testJSONDownload()
		
		let url = "https://www.codementor.io/blog/land-clients-freelance-developer-39w3i166wy?utm_content=posts&amp;utm_source=sendgrid&amp;utm_medium=email&amp;utm_term=post-39w3i166wy&amp;utm_campaign=newsletter20180516"
		let request = Plug.request(url: url)
		request.addHeader(header: .accept(["*/*"]))
		
		request.completion { request, data in
			print(data)
		}.error { request, error in
			print(error)
		}
		return true
	}
	
	func testBulkDownload() {
		var count = testImageURLs.count
		for url in testImageURLs {
			let connection = Connection(url: url)!
			connection.completion() { conn, data in
				count -= 1
				print("\(count) left")
				if count == 0 { print("All Done") }
			}.error { conn, error in
				print("BulkDownload Error: \(error)")
				count -= 1
				if count == 0 { print("All Done") }
			}
			
			connection.start()
		}
	}

	func applicationWillResignActive(_ application: UIApplication) {
	}

	func timeoutTests() {
		Plug.instance.timeout = 35.0
		
		//let largeURL = URL(string: "https://developer.apple.com/services-account/download?path=/iOS/iAd_Producer_5.1/iAd_Producer_5.1.dmg")!
		
		let url = URL(string: "https://192.168.1.62")!
		let request = Plug.request(method: .GET, url: url)
		
		_ = request.completion { req, data in
			print("complete")
		}
		
		_ = request.error { req, error in
			print("Error: \(error)")
		}
		
		request.start()
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		let url = "https://serenitynow.herokuapp.com/devices/online"
		let args: JSONDictionary = ["device": ["udid": UIDevice.current.identifierForVendor!.uuidString]]
	
		Plug.request(method: .DELETE, url: url, parameters: Plug.Parameters.json(args)).completion { conn, data in
			print("got it \(String(data: data.data, encoding: .utf8) ?? "-- no data --")")
		}.start()
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
	}

	func applicationWillTerminate(_ application: UIApplication) {
	}


}

let testImageURLs = ["https://upload.wikimedia.org/wikipedia/commons/d/d6/Black_Brant.jpg", "https://tse1.mm.bing.net/th?id=OIP.VYzdON_lOj-zJ0AcKUheogDtEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/9/94/Ariane_rocket_at_Bourget_airport_museum,_Paris.JPG", "https://tse2.mm.bing.net/th?id=OIP.nJvI0vt-k7eF4gsQA0P0BgEsDg&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/1/10/CELstart-rocket.png", "https://tse2.mm.bing.net/th?id=OIP.S_1vEWcqADOZJxa_osSUwQCvCv&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/7/74/V2_rocket.JPG", "https://tse3.mm.bing.net/th?id=OIP.Vi5_hkgtVBFMVShdcIg1cwDMEy&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/Viking_5C_rocketengine.jpg/1200px-Viking_5C_rocketengine.jpg", "https://tse1.mm.bing.net/th?id=OIP._F_5f6JyVwK8pcgONAgobwDIEs&pid=Api", "https://i.stack.imgur.com/ywkBm.jpg", "https://tse4.mm.bing.net/th?id=OIP.Q58LJJuA3L6KtQMirN4FZwHaF2&pid=Api", "http://www.clker.com/cliparts/1/1/f/4/y/e/my-rocket-hi.png", "https://tse1.mm.bing.net/th?id=OIP.phF3yMvd2O53W-PaX9DlmQDnEs&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/c/cb/Antares_rocket_launch_April_21%2C_2013.jpg", "https://tse3.mm.bing.net/th?id=OIP.FBArMfiByDPuTTSOgeoTkAEsDz&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/7/73/Zenit-2_rocket_ready_for_launch.jpg", "https://tse3.mm.bing.net/th?id=OIP.J-Ewkyr6_yZIfQ96WjkVTwDPEt&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/2/27/Soyuz_rocket_ASTP.jpg/1200px-Soyuz_rocket_ASTP.jpg", "https://tse1.mm.bing.net/th?id=OIP.C-OyPHpbZnW2CvSEK1NSAADMEs&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/1/17/Saturn_v_space_rocket_at_us_space_and_rocket_center.jpg", "https://tse4.mm.bing.net/th?id=OIP.L_KTqKRTetghMeNM2ykdCQDhEs&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/1/12/Soyuz_rocket_assembly.jpg", "https://tse1.mm.bing.net/th?id=OIP.cAAGZRI0u598IoXv7SmdzwEsDD&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/0/0d/Antares_Rocket_Test_Launch.jpg", "https://tse3.mm.bing.net/th?id=OIP.eR7n4hSqV_wo0ZVwkK5qAwDHEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/9/9a/N1_rocket_drawing.png", "https://tse1.mm.bing.net/th?id=OIP.QM8e1PavbDv1Jp9WrCNJjABJEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/8/8b/Titan_23G_rocket.gif", "https://tse4.mm.bing.net/th?id=OIP.Wjfb-EFZ7T1dTkWUrGmilgDKEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/e/e2/Nova_Rocket.jpg", "https://tse3.mm.bing.net/th?id=OIP.DvfbBOvywR3qfLALibbuNgEsDw&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/e/e6/Soyuz_TMA-05M_rocket_launches_from_Baikonur_4.jpg", "https://tse3.mm.bing.net/th?id=OIP.YTUNQSbzqBQSM8Ds8jD2vgEsDL&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/0/01/S-5M_57_mm_rocket.jpg", "https://tse3.mm.bing.net/th?id=OIP.zsS32hSrmr2jwUDpxMpN2gEsCv&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/1/17/Apollo_Pad_Abort_Test_-2.jpg", "https://tse4.mm.bing.net/th?id=OIP.MLJbCL8JGwZrAzy97cVwoAD9Es&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/2/2a/Proton_rocket_launch.jpg", "https://tse2.mm.bing.net/th?id=OIP.8OgW54jOugKQQWvl52iCHADFEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/5/5c/SpaceX%E2%80%99s_Falcon_9_Rocket_%26_Dragon_Spacecraft_Lift_Off.jpg", "https://tse4.mm.bing.net/th?id=OIP.7rTAlLBj2yy7aUq0BZIsrAEsDH&pid=Api", "https://ycphysicalscience.wikispaces.com/file/view/rocket.png/129514411/rocket.png", "https://tse2.mm.bing.net/th?id=OIP.jjdr-xlAwhyFCro9Q5pyjAEsEG&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/1/1f/Titan_Missile_Family.png", "https://tse3.mm.bing.net/th?id=OIP.Sa1JAlMtzd2XS_9cu8hW3gEsEL&pid=Api", "http://fc09.deviantart.net/fs23/i/2007/343/0/3/Rocket_launch_by_Baietu.jpg", "https://tse4.mm.bing.net/th?id=OIP.n6me6H-XLI2-1qjMvI0UtQEsC_&pid=Api", "http://fc03.deviantart.net/fs70/i/2011/305/1/7/retro_rocket_by_galantyshow-d4epeg4.png", "https://tse3.mm.bing.net/th?id=OIP.2D4VdiGGdpPrv-h_kgFF6AEsCo&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/6/6e/Athena_1_rocket_launching_from_Kodiak_Island.jpg", "https://tse3.mm.bing.net/th?id=OIP.npwzS5DSW0Y0h4Gzy9G9GADKEs&pid=Api", "http://images.uncyc.org/commons/thumb/0/05/Rocket.svg/768px-Rocket.svg.png", "https://tse4.mm.bing.net/th?id=OIP.1htTlPqAEbtryRIkJOoqZAEsEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/a/ac/Titan_IV_rocket.jpg", "https://tse1.mm.bing.net/th?id=OIP.rUHLZIqAWAX4UwtUVW02MwCMEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/0/04/Astris_Rocket.jpg", "https://tse2.mm.bing.net/th?id=OIP.DZHxQeliuQwFmj7r9HIQegDhEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/3/33/T-34-rocket-launcher-France.jpg/1200px-T-34-rocket-launcher-France.jpg", "https://tse1.mm.bing.net/th?id=OIP.HhAl5zSx1Keu4OIgfpz50wEYDf&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/1/14/Proton_Zvezda_crop.jpg", "https://tse1.mm.bing.net/th?id=OIP.ink04fbh586g2uWXfbzztgDOEs&pid=Api", "http://exploration.grc.nasa.gov/education/rocket/gallery/titan/GeminiTitan.jpg", "https://tse4.mm.bing.net/th?id=OIP.bvyZ3udV_jxlQmTUzdlnBgHaK5&pid=Api", "http://1.bp.blogspot.com/-hI4B-1jseIM/UqJmuXsQENI/AAAAAAAAglo/f94Kbz_T7mg/s1600/Rocket_8304_VETS_08.jpg", "https://tse3.mm.bing.net/th?id=OIP.8PpTwB89LL4l6k7RtkbHrACMEs&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/2/26/MSFC_rocket_1960s.jpg", "https://tse3.mm.bing.net/th?id=OIP._r_qVk2fAEGmHjrV0o018ADgEs&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/f/f4/Mercury_spacecraft_attached_to_rocket.jpg", "https://tse2.mm.bing.net/th?id=OIP.VAE88VaQcakr4lKxaAhgCwDvEs&pid=Api", "http://boingboing.net/wp-content/uploads/2012/03/rocket.jpg", "https://tse2.mm.bing.net/th?id=OIP.c0wPTpcwmz-KaITqy2q-ZgFGC_&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/thumb/b/bb/Vanguard_rocket.jpg/270px-Vanguard_rocket.jpg", "https://tse3.mm.bing.net/th?id=OIP.xvoyqs8bCr1Uk3B7nwuH2ADqEs&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/2/28/V-2_rocket_in_Historisch-technisches_Informationszentrum_Peenem%C3%BCnde_(1).JPG", "https://tse2.mm.bing.net/th?id=OIP.reQjra6XVimW13zUSPiSSwDIEs&pid=Api", "https://hacksperger.files.wordpress.com/2013/03/nrol-25-delta4-rocket-ascent.jpg", "https://tse4.mm.bing.net/th?id=OIP.yhCcbribcITKVhUcpfwnIgDIEs&pid=Api", "http://fc00.deviantart.net/fs46/i/2009/191/5/5/Saturn_V_rocket_Vector_100_by_rogelead.jpg", "https://tse4.mm.bing.net/th?id=OIP.QCezad0uMt66heWmfTW6dwHaL_&pid=Api", "http://teachers.egfi-k12.org/wp-content/uploads/2012/06/rolling-rocket.gif", "https://tse1.mm.bing.net/th?id=OIP.F-oSmMjafllbFEF6eCwepgEsDh&pid=Api", "http://img12.deviantart.net/0d50/i/2014/315/7/a/n1_moon_rocket_vexel_by_firmato-d2qugwh.jpg", "https://tse2.mm.bing.net/th?id=OIP.F29El9T7LdBtlK8UsrLhJQCpEs&pid=Api", "http://www.learnwithmac.com/wp-content/uploads/2012/08/rocketlaunch.png", "https://tse4.mm.bing.net/th?id=OIP.cnHCXSQSXXDPZKJKE3KzlAEsDh&pid=Api", "http://fc08.deviantart.net/fs71/f/2012/076/0/0/retro_rocket_launch_by_avero-d4t1ns5.jpg", "https://tse1.mm.bing.net/th?id=OIP.URWosga-FtUSy2CJ7m_zkAEsDh&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/e/ed/Soyuz_TMA-06M_rocket_launches_from_Baikonur_1.jpg", "https://tse3.mm.bing.net/th?id=OIP.a922Fc8-4zwXkCABDm-JdQHaK1&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/1/10/Taurus_rocket.jpg", "https://tse2.mm.bing.net/th?id=OIP.00Z6py9QmvOKXAANRwhOXQCeEs&pid=Api", "http://en.bilimmerkezi.com.tr/media/en/large/rocket.jpg", "https://tse2.mm.bing.net/th?id=OIP.U8chFYQWlWq7SXE7ZPTTDwEsCP&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/9/9d/Rocket.jpg", "https://tse4.mm.bing.net/th?id=OIP.kwPbbW3uEcnX8BMtnlVymwEsDD&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/2/2f/The_Launch_of_Long_March_3B_Rocket.jpg", "https://tse2.mm.bing.net/th?id=OIP.KBrQfJ2NMAwUu30mUB7FSAHaKJ&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f8/JMS_0067Crop.jpg/1200px-JMS_0067Crop.jpg", "https://tse4.mm.bing.net/th?id=OIP.U7dvMrrEmvBMfbIaiidvyADwEs&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/0/0c/Saturn_Rocket_Family_Comparison.jpg", "https://tse4.mm.bing.net/th?id=OIP.u7ar3KZTQ5IoFjOPRflZegEsED&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/2/26/Russia-Moscow-VDNH-Rocket_R-7-2.jpg", "https://tse2.mm.bing.net/th?id=OIP.DipgtR32kCR5KODXmM_1yADgEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/2/26/USSRC_Rocket_Park.JPG", "https://tse2.mm.bing.net/th?id=OIP.zTbsyllW-69p2XOtwLtUkQEsDI&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/Sojuz_TMA-9_into_flight.jpg/1200px-Sojuz_TMA-9_into_flight.jpg", "https://tse1.mm.bing.net/th?id=OIP.LHSAXQ2v9lEQiJkj8YCc3QC8Es&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/7/70/Titan_III%2823%29C_rocket.jpg", "https://tse3.mm.bing.net/th?id=OIP.6Rixg1vcQELSyBUKdnKYAgDrEs&pid=Api", "http://doejo.com/wp-content/uploads/old/wallpapers/doejo-rocket-green-1024x768.jpg", "https://tse4.mm.bing.net/th?id=OIP.DS2InHer3vjJNR3dfNWjNQEsDh&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/e/ec/Magnum_Booster_Rocket.jpg", "https://tse1.mm.bing.net/th?id=OIP.37zwxAAkHLWUIedb8GB7hgF6Hg&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/f/ff/Juno_II_rocket.jpg", "https://tse1.mm.bing.net/th?id=OIP.gic7rKCSsLO30icCN8BuvgDMEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/0/0c/Model_rocket_parts.gif", "https://tse2.mm.bing.net/th?id=OIP.1m_Xx_czR_ZG5L-erCF-BgEsDh&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/STS-134_launch_2.ogv/1200px--STS-134_launch_2.ogv.jpg", "https://tse1.mm.bing.net/th?id=OIP.blDYSVnsGsyF1MPzlu_ZEAFNC7&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/3/39/Asp_rocket.jpg", "https://tse1.mm.bing.net/th?id=OIP.XbApWtpfHT9LGMnENut5VgD9Es&pid=Api", "https://upload.wikimedia.org/wikipedia/en/thumb/a/aa/Rocket1034040.jpg/250px-Rocket1034040.jpg", "https://tse1.mm.bing.net/th?id=OIP.K58yjbicIkSpFdXwZaEBpwHaNC&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/thumb/c/c4/Model_rocket_launch_2_%28Starwiz%29.jpg/220px-Model_rocket_launch_2_%28Starwiz%29.jpg", "https://tse1.mm.bing.net/th?id=OIP.pX7ExOlz8H0yEVsI3nV17QDIEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/8/87/Iss-expedition_13-launch.jpg", "https://tse2.mm.bing.net/th?id=OIP.Q6JL-zU0fQ0JQKqGWLFWJAC7Es&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/2/2f/Soyuz_TMA-06M_rocket_launches_from_Baikonur_2.jpg", "https://tse4.mm.bing.net/th?id=OIP.JE_gdj55n3cp8U22X0AK4QEsDH&pid=Api", "http://doejo.com/wp-content/uploads/old/wallpapers/doejo-rocket-green-1280x800.jpg", "https://tse2.mm.bing.net/th?id=OIP.2Ja1Kbtgoibj9vPeIcyzcQEsC7&pid=Api", "http://www.russianspaceweb.com/images/spacecraft/military/imint/kondor/kondor_e/launch_vertical_1.jpg", "https://tse4.mm.bing.net/th?id=OIP.qxbSRh4dN0_cbtestSdPTgDIEs&pid=Api", "http://th06.deviantart.net/fs71/PRE/i/2010/161/4/7/N1_Moon_Rocket_VEXEL_by_rogelead.jpg", "https://tse1.mm.bing.net/th?id=OIP.8EK-c2th2U4LYPyNJ2hfYwDIEs&pid=Api", "http://exploration.grc.nasa.gov/education/rocket/Images/rktbot.gif", "https://tse3.mm.bing.net/th?id=OIP.SMwOHFPpQGXjcyLtKaERVwEsDh&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Scout_launch_vehicle.jpg/1200px-Scout_launch_vehicle.jpg", "https://tse3.mm.bing.net/th?id=OIP.ZXIm1Si8KbvFtfpHfdkMywHaJY&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/2/2b/Russia-Moscow-VDNH-Rocket_R-7-1.jpg", "https://tse4.mm.bing.net/th?id=OIP.LILso-DOCy3sQ2uP8XiNmADgEs&pid=Api", "https://i.stack.imgur.com/nabSt.jpg", "https://tse3.mm.bing.net/th?id=OIP.aYSHnDuWQfijKvZw-xwo1QEsCo&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/Indian_carrier_rockets.svg/550px-Indian_carrier_rockets.svg.png", "https://tse1.mm.bing.net/th?id=OIP.EbmmxyXZkmYpmUFrqfvwegEsEJ&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/e/e5/Fus%C3%A9e_VERONIQUE_%288727147868%29.jpg", "https://tse1.mm.bing.net/th?id=OIP.afLKp4dEdv75r97KUe0TQwDBEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/STS-125_Atlantis_Liftoff_02.jpg/1200px-STS-125_Atlantis_Liftoff_02.jpg", "https://tse4.explicit.bing.net/th?id=OIP.KGayiz_kPJCMVOGuHSdJWQExDM&pid=Api", "https://futurism.com/wp-content/uploads/2016/04/spacex.png", "https://tse2.mm.bing.net/th?id=OIP.HK-lbfI0zcJcjQHmtxuq1wDOEv&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d2/Rktfor.gif/170px-Rktfor.gif", "https://tse1.mm.bing.net/th?id=OIP.LqA3ro-dlKCJ_bK_fB57oQCqEU&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/8/89/Centaur_rocket_stage.jpg", "https://tse3.mm.bing.net/th?id=OIP.FhUfxXRRweIM_N81MBF5cADOEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/7/70/Saturn_V-Shuttle-Ares_I-Ares_V-Ares_IV_comparison.jpg", "https://tse3.mm.bing.net/th?id=OIP.VgVaPenQIbd3EzDH1o9ALQEsC_&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Pioneer_I_on_the_Launch_Pad_-_GPN-2002-000204.jpg/1200px-Pioneer_I_on_the_Launch_Pad_-_GPN-2002-000204.jpg", "https://tse2.mm.bing.net/th?id=OIP.gi4kQx6JxHrUi4jLS5M96wDfEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/2/23/Oracle_rocket.jpg", "https://tse1.mm.bing.net/th?id=OIP.sgizJyaKxQ2QaGljVwehngEsDg&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/8/80/Hera_rocket_on_launch_pad.jpg", "https://tse4.mm.bing.net/th?id=OIP.GsE9I60IxSXBcGZuBkJKhQD8Es&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/e/e0/Soyuz_TMA-06M_rocket_launches_from_Baikonur_5.jpg", "https://tse4.mm.bing.net/th?id=OIP.y0Ay4_gD5pGfHi9CztHiqgDLEy&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/Flickr_-_Israel_Defense_Forces_-_Eight_Qassam_Launchers_in_Gaza.jpg/1200px-Flickr_-_Israel_Defense_Forces_-_Eight_Qassam_Launchers_in_Gaza.jpg", "https://tse2.mm.bing.net/th?id=OIP.fQI7W_U3G7wHJFhd8xtq1gE0DK&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/6/69/Delta_IV_Medium_Rocket_DSCS.jpg", "https://tse4.mm.bing.net/th?id=OIP.kcGRlInaU80yKvMqm5TCNwDIEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/9/94/Soyuz_TMA-3_launch.jpg", "https://tse1.mm.bing.net/th?id=OIP.oPbOugdl7t-dwy8H1IluTwHaLS&pid=Api", "http://www.grc.nasa.gov/WWW/k-12/rocket/Images/rktaero.gif", "https://tse4.mm.bing.net/th?id=OIP.hDk7wx-OwS8DkYdfvVVY8AEsDh&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/Antares_A-ONE_launch.2.jpg/1200px-Antares_A-ONE_launch.2.jpg", "https://tse1.mm.bing.net/th?id=OIP.WVsFY97vJo1x3gfxA-3ftAHaIy&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Rocket_man02_-_melbourne_show_2005.jpg/1200px-Rocket_man02_-_melbourne_show_2005.jpg", "https://tse3.mm.bing.net/th?id=OIP.66nwafdn72faU_PsBHw9_QEsDI&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/9/94/Delta_II_7925_%282925%29_rocket_with_Deep_Impact.jpg", "https://tse1.mm.bing.net/th?id=OIP.wPEhUYTTW11L6GTWYvbpqQDHEs&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/4/43/M_powered_rocket.jpg", "https://tse3.mm.bing.net/th?id=OIP.J6oojGR-I-uTAgKqtoKkVQDiEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f7/N1+Saturn5.jpg/170px-N1+Saturn5.jpg", "https://tse1.mm.bing.net/th?id=OIP.JJy8HKlh9JfSIvkCpzPaMgCiEs&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/f/fd/Soyuz_TMA-05M_rocket_launches_from_Baikonur_2.jpg", "https://tse3.mm.bing.net/th?id=OIP.cqNKlspNFY0e5nbwtIzcgQDHEs&pid=Api", "https://rocketxtreme.wikispaces.com/file/view/rockpart.gif/225419904/457x334/rockpart.gif", "https://tse2.mm.bing.net/th?id=OIP.kcNYRCKeq8fOLoOJS6lsNgEsDb&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Soyuz_ASTP_rocket_launch.jpg/1280px-Soyuz_ASTP_rocket_launch.jpg", "https://tse3.mm.bing.net/th?id=OIP.pE6HT_FX4Rn6ITmqopa72gEsDw&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/6/69/Delta_Rocket_Telstar1.jpg", "https://tse1.mm.bing.net/th?id=OIP.WHPQg0rxZ_pb34j8KG9gAgDqEs&pid=Api", "http://ocw.mit.edu/courses/aeronautics-and-astronautics/16-512-rocket-propulsion-fall-2005/16-512f05.jpg", "https://tse2.mm.bing.net/th?id=OIP.-X0SlJUzy6SoZd2BSqGA7AHaIM&pid=Api", "https://successfulsoftware.files.wordpress.com/2015/09/estes-helicat-rocket.jpg", "https://tse3.mm.bing.net/th?id=OIP.DKgmXSuV3-NYKm8KRUrgTQEsDl&pid=Api", "http://philschatz.com/physics-book/resources/Figure_09_07_02a.jpg", "https://tse3.mm.bing.net/th?id=OIP.xMgZs8lpLYQEDC15n5gtuQDgEs&pid=Api", "http://www.quirkysanfrancisco.com/wp-content/uploads/2010/08/Rocket-Ship-Artwork-on-the-Embarcadero-08.jpg", "https://tse2.mm.bing.net/th?id=OIP.oSeGqVRcKGpn3lsXE0qfBQEsCo&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/thumb/2/2b/MuRockets.svg/618px-MuRockets.svg.png", "https://tse3.mm.bing.net/th?id=OIP.HfCBQq2-_2keQxS9YqiCLQHaGY&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/2/22/Cape_canaveral_atlas_rocket_launch.jpg", "https://tse1.mm.bing.net/th?id=OIP.P67BN2E43J8K-3DskJkwzwEsDI&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/7/73/Soyuz_TMA-07M_rocket_erection_2.jpg", "https://tse3.mm.bing.net/th?id=OIP.ecjL0ql51XmlL5QIWnZqeAHaE7&pid=Api", "http://www.hk-phy.org/energy/transport/trans_phy/images/rocket_launch.gif", "https://tse3.mm.bing.net/th?id=OIP.uC24SIZKpvTZ4ZjkAIe8dwDhEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/6/63/Rocket_size_comparison.png", "https://tse4.mm.bing.net/th?id=OIP.5xbR4ewhlOKU8ECpHBHyHgEsC6&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/0/02/Rohini_rockets_family_shapes-03.jpg", "https://tse4.mm.bing.net/th?id=OIP.gQrjbzJgs8mIFTrtFfiD5gEsCs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/8/8b/Rocket.gif", "https://tse1.mm.bing.net/th?id=OIP.0Qwe1VjfLnv0zOmTi__TgQCrEC&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/V-2_rocket_diagram_(with_English_labels).svg/767px-V-2_rocket_diagram_(with_English_labels).svg.png", "https://tse1.mm.bing.net/th?id=OIP.8FiC3bHg_jJl0w6M7xzpvQDgEs&pid=Api", "http://3.bp.blogspot.com/-PVIgsOWEYVA/UdtKImO8DwI/AAAAAAAAECA/uSOG38OLnEA/s400/Vintage+rocket+1.jpg", "https://tse2.mm.bing.net/th?id=OIP.aPz3PnVPqVwoj9AXnY3UDgEsDx&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/3/38/Soyuz_ASTP_rocket_launch.jpg", "https://tse4.mm.bing.net/th?id=OIP.BYGPlkHD97sUUBZL77sMmwHgGC&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/0/0c/Improved_Orion_Sounding_Rocket-01.jpg", "https://tse1.mm.bing.net/th?id=OIP.cayCZbvRzSly6a-Y5aWWQQDSEs&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/f/f9/Soyuz_TMA-06M_rocket_launches_from_Baikonur_3.jpg", "https://tse1.mm.bing.net/th?id=OIP.72UkIOiPyzx8nf_NwAa2uQEsDI&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/a/ae/RAR2009_-_Rocket_Car.jpg", "https://tse1.mm.bing.net/th?id=OIP.emMcSFxUsukiaYqSjV51hAEsCd&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/6/69/Brazilian_Sonda_III_rocket_shapes.jpg", "https://tse1.mm.bing.net/th?id=OIP._G7zLDtuY1L-hNKyCiZaDQEsEH&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/4/4c/Vanguard_rocket_vanguard1_satellite.jpg", "https://tse3.mm.bing.net/th?id=OIP.LPlFvignchpOHPs0VM6T7ABhEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/8/87/Nasa_rocketgarden.JPG", "https://tse2.mm.bing.net/th?id=OIP.no7eFN4nYjNmQ8XD801hJAEsDg&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/c/c1/Xcor-rocketracer-N216MR-071029-07cr-7.jpg", "https://tse4.mm.bing.net/th?id=OIP.wIDBASY8eezIdk4Bamqj4AEsDZ&pid=Api", "https://static.vecteezy.com/system/resources/previews/000/047/447/original/rocket-vector.jpg", "https://tse3.mm.bing.net/th?id=OIP.Vsw12Hu2EklflR-vVo-EfgEsDS&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/7/7c/Delta_II_rocket.jpg", "https://tse2.mm.bing.net/th?id=OIP.KfIm5hLGDTVbTIPaKu5u2ADwEs&pid=Api", "http://www.robotroom.com/Launch-Controller/Model-rocket-lift-off.png", "https://tse1.mm.bing.net/th?id=OIP.eshwtZWSO4wYaXfn0RdQ6wEsD3&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/8/87/Delta_II_rocket_lift_off.jpg", "https://tse3.mm.bing.net/th?id=OIP.ZabgMccCfzE6HqrhrpY5ggB8Es&pid=Api", "http://2.bp.blogspot.com/-ablgso0Dqvk/VdxWLEZ7P3I/AAAAAAAANwU/hjVkqGZTU30/s1600/the%2Bmoon%2Bcollectible%2Brocket%2Bjeff%2Bbrewer%2Bcool%2Brockets.jpg", "https://tse1.mm.bing.net/th?id=OIP.TTvQhQYWPsKwf6ZUHo4fzwEsEs&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/7/79/Semyorka_Rocket_R7_by_Sergei_Korolyov_in_VDNH_Ostankino_RAF0540.jpg", "https://tse4.mm.bing.net/th?id=OIP.epN39zE601ai8E206dbM3gDhEs&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/a/aa/Mod-Rocket-Nosecone-Hovering.jpg", "https://tse1.mm.bing.net/th?id=OIP.dLzShnFqdxjSDTENlUjl1ADIEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/Haas_2_rocket_with_IAR_111_supersonic_plane.jpg/250px-Haas_2_rocket_with_IAR_111_supersonic_plane.jpg", "https://tse4.mm.bing.net/th?id=OIP.deGn7Xg5jJ-qKXw9tjfagQHaKh&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f2/Zuni_unguided_rocket.jpg/1200px-Zuni_unguided_rocket.jpg", "https://tse3.mm.bing.net/th?id=OIP.PfVlEuhv-U7wGOFurC8xHgEsDI&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/a/ae/R-7-rocket_on_display_in_Moscow.jpg", "https://tse1.mm.bing.net/th?id=OIP.yILHr0rA75ZRac9yE-ZyqgDhEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7c/Goddard_and_Rocket.jpg/834px-Goddard_and_Rocket.jpg", "https://tse2.mm.bing.net/th?id=OIP.o_27-UoQMy42Hp4lgMyyKQD0Es&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/a/ab/Atlas_EELV_family.png", "https://tse4.mm.bing.net/th?id=OIP.oYmFb3und83j3q2CLBzCNAHaHa&pid=Api", "http://fc09.deviantart.net/fs49/i/2009/156/8/c/Soyuz_Rocket_and_Kliper_by_rogelead.jpg", "https://tse4.mm.bing.net/th?id=OIP.pN1p6laDM21uTSA1dLi6QgDHEs&pid=Api", "http://i.stack.imgur.com/Pr8Td.jpg", "https://tse4.mm.bing.net/th?id=OIP.4W1hUA4hvlWMRnDgg_oW0ADwEs&pid=Api", "https://taholtorf.files.wordpress.com/2012/11/rocket.jpg", "https://tse4.mm.bing.net/th?id=OIP.As0Nnjvo-rRuunS-SKCYFQEsDn&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8b/Saturn_SA9_launch.jpg/1200px-Saturn_SA9_launch.jpg", "https://tse2.mm.bing.net/th?id=OIP.HUk7BWxsLdzaLR_NOWmzrgDjEs&pid=Api", "https://i.stack.imgur.com/MfqKu.jpg", "https://tse1.mm.bing.net/th?id=OIP.A5PcZcgLhkI6M5h0lXKM-gHaFn&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/0/02/CMST-Convair_Atlas_Rocket.jpg", "https://tse2.mm.bing.net/th?id=OIP.23CHcfSxFT5mJw8Y8WtbFACREs&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/1/1f/Apollo_11_Launched_Via_Saturn_V_Rocket.jpg", "https://tse3.mm.bing.net/th?id=OIP.NoumbGaY9tShg4SwiKXkjgHaIO&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/1/10/LRO-LCROSS_Atlas_V-Centaur_rocket_at_Launch_Complex_41.jpg", "https://tse4.mm.bing.net/th?id=OIP.5En4vpX8e9tLeNdQpR-VWgC5Es&pid=Api", "http://physics30rockets.wikispaces.com/file/view/rocket_thrust_2.png/179238931/316x399/rocket_thrust_2.png", "https://tse1.mm.bing.net/th?id=OIP.NaioWQ7245bRD9j2HutSHADeEY&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/7/7f/H-II_Rocket_at_Tsukuba_Expo_Center.jpg", "https://tse3.mm.bing.net/th?id=OIP.R_f8taLko8y99OrA_DfvqQDhEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/Antimatter_Rocket.jpg/1200px-Antimatter_Rocket.jpg", "https://tse2.mm.bing.net/th?id=OIP.4jT1jEn9foJgQkDpgjk7CAEsDw&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Soyuz_TMA-9_launch.jpg/1200px-Soyuz_TMA-9_launch.jpg", "https://tse3.mm.bing.net/th?id=OIP.Scf62ejSdrZtsO0DSnbwwQDLEy&pid=Api", "http://img10.deviantart.net/8653/i/2013/186/f/2/arcas_sounding_rocket_by_visualmotionmedia-d6c3pjs.jpg", "https://tse2.mm.bing.net/th?id=OIP.ezVhsH4eOiWUH-e5BPrwAwEsCo&pid=Api", "https://sajeevkmenon.files.wordpress.com/2013/03/rocket.jpg", "https://tse3.mm.bing.net/th?id=OIP.NgM8rjaylvVc4euThbY7-wDID8&pid=Api", "http://fc00.deviantart.net/fs70/f/2012/341/4/8/animated_sombrero_rocket_by_fyrenwater-d5ndm44.gif", "https://tse1.mm.bing.net/th?id=OIP.tCYQTRxOFHf1SYua4bd2jQHaHa&pid=Api", "http://th02.deviantart.net/fs70/PRE/i/2011/323/c/5/n1_rocket___russia_by_tylerskrabek-d4gpqei.jpg", "https://tse3.mm.bing.net/th?id=OIP.dA72Jk8IU0VZRaNCNgC7AgDBEs&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/8/8e/Delta_IV_Heavy_Rocket.jpg", "https://tse3.mm.bing.net/th?id=OIP.-nTL8UYppc-PhqYDr_MBOwHaLH&pid=Api", "http://img10.deviantart.net/3e49/i/2010/080/7/9/retro_rocket_2_by_ohfive30.jpg", "https://tse3.mm.bing.net/th?id=OIP.5MS7uc4RBtucvsEVwdeKPAEsCo&pid=Api", "http://upload.wikimedia.org/wikipedia/commons/f/f3/Soyuz_TMA-01M_rocket_launches.jpg", "https://tse3.mm.bing.net/th?id=OIP.8GM8-U35J5WsGiHAZnPXiADREs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/0/06/Empty_Water_Rocket.png", "https://tse2.mm.bing.net/th?id=OIP.jHDGxHe0l8xXRhxm-V7m-ACfEs&pid=Api", "https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/KH-8_N1.jpg/1920px-KH-8_N1.jpg", "https://tse1.mm.bing.net/th?id=OIP.Fim1T5Iw6-4f95brZDFNxADZEe&pid=Api"].map { URL(string: $0)! }
