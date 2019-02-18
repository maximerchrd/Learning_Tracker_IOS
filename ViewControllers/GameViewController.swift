import UIKit

class GameViewController: UIViewController {
    
    @IBOutlet weak var blueScore: UILabel!
    @IBOutlet weak var redScore: UILabel!
    @IBOutlet weak var blueClimber: UIImageView!
    @IBOutlet weak var redClimber: UIImageView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var celebration: UIImageView!
    @IBOutlet weak var readyButton: UIButton!
    
    var redCelebration = [#imageLiteral(resourceName: "red_celeb_frontleft"),#imageLiteral(resourceName: "red_celeb_rightback"),#imageLiteral(resourceName: "red_celeb_frontleft"),#imageLiteral(resourceName: "red_celeb_rightfront"),#imageLiteral(resourceName: "red_celeb_leftback"),#imageLiteral(resourceName: "red_celeb_rightfront")]
    var blueCelebration = [#imageLiteral(resourceName: "blue_celeb_1"),#imageLiteral(resourceName: "blue_celeb_2")]
    var gameView: GameView = GameView()
    
    var blueXDistance: CGFloat = 0.0
    var blueYDistance: CGFloat = 0.0
    var redXDistance: CGFloat = 0.0
    var redYDistance: CGFloat = 0.0
    
    var blueXOrigin: CGFloat = 0.0
    var blueYOrigin: CGFloat = 0.0
    var redXOrigin: CGFloat = 0.0
    var redYOrigin: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ClassroomActivityViewController.navGameViewController = self
        blueXOrigin = blueClimber.frame.origin.x
        blueYOrigin = blueClimber.frame.origin.y
        redXOrigin = redClimber.frame.origin.x
        redYOrigin = redClimber.frame.origin.y
        
        blueXDistance = celebration.frame.origin.x - blueClimber.frame.origin.x
        blueYDistance = celebration.frame.origin.y - blueClimber.frame.origin.y
        redXDistance = celebration.frame.origin.x - redClimber.frame.origin.x
        redYDistance = celebration.frame.origin.y - redClimber.frame.origin.y
        
        if gameView.team == 1 {
            self.blueScore.text = "Me: 0"
            self.redScore.text = "0"
        } else {
            self.blueScore.text = "0"
            self.redScore.text = "Me: 0"
        }
        
        if gameView.gameType != GameView.orderedAutomaticSending && gameView.gameType != GameView.randomAutomaticSending {
            readyButton.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        readyButton.backgroundColor = #colorLiteral(red: 0.968627451, green: 0.307537024, blue: 0.2841172663, alpha: 1)
        ClassroomActivityViewController.launchFromQrCode(viewController: self)
    }
    
    @IBAction func qrCodeReading(_ sender: Any) {
        if let newViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ScanQRCodeViewController") as? ScanQRCodeViewController {
            if let navigator = self.navigationController {
                navigator.pushViewController(newViewController, animated: true)
            } else {
                NSLog("%@", "Error trying to show Scan QR code: the view controller wasn't pushed on a navigation controller")
            }
        }
    }
    
    @IBAction func ready(_ sender: Any) {
        let transferable = ClientToServerTransferable(prefix: ClientToServerTransferable.readyPrefix)
        transferable.optionalArgument1 = UIDevice.current.identifierForVendor!.uuidString
        AppDelegate.wifiCommunicationSingleton?.sendData(data: transferable.getTransferableData())
        readyButton.backgroundColor = #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)
    }
    
    public func changeScore(teamOneScore: Double, teamTwoScore: Double) {
        let percentToGoalOne = CGFloat(teamOneScore / Double(gameView.endScore))
        let percentToGoalTwo = CGFloat(teamTwoScore / Double(gameView.endScore))
        let newBlueX = blueXOrigin + percentToGoalOne * blueXDistance
        let newBlueY = blueYOrigin + percentToGoalOne * blueYDistance
        let newRedX = redXOrigin + percentToGoalTwo * redXDistance
        let newRedY = redYOrigin + percentToGoalTwo * redYDistance
        DispatchQueue.main.async {
            if percentToGoalOne == 1 {
                self.blueClimber.isHidden = true
                self.celebration.isHidden = false
                self.celebration.animationImages = self.blueCelebration
                self.celebration.animationDuration = 1.2
                self.celebration.startAnimating()
            } else if percentToGoalTwo == 1 {
                self.redClimber.isHidden = true
                self.celebration.isHidden = false
                self.celebration.animationImages = self.redCelebration
                self.celebration.animationDuration = 4
                self.celebration.startAnimating()
            } else {
                self.redClimber.isHidden = false
                self.blueClimber.isHidden = false
                self.celebration.isHidden = true
                self.blueClimber.frame.origin.x = newBlueX
                self.blueClimber.frame.origin.y = newBlueY
                self.redClimber.frame.origin.x = newRedX
                self.redClimber.frame.origin.y = newRedY
            }
            if self.gameView.team == 1 {
                self.blueScore.text = "Me: " + String(teamOneScore)
                self.redScore.text = String(teamTwoScore)
            } else {
                self.blueScore.text = String(teamOneScore)
                self.redScore.text = "Me: " + String(teamTwoScore)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
