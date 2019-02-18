import UIKit

class GameViewController: UIViewController {
    
    @IBOutlet weak var blueScore: UILabel!
    @IBOutlet weak var redScore: UILabel!
    @IBOutlet weak var blueClimber: UIImageView!
    @IBOutlet weak var redClimber: UIImageView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var celebration: UIImageView!
    
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
    }
    
    @IBAction func qrCodeReading(_ sender: Any) {
    }
    
    @IBAction func ready(_ sender: Any) {
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
