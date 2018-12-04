/*
* ...
* @author fox
*/
import com.GameInterface.DistributedValue;
import com.Utils.Archive;
import mx.utils.Delegate;

class com.fox.HPP {
	private var mode:DistributedValue;
	private var decimals:DistributedValue;
	
	public static function main(swfRoot:MovieClip):Void	{
		var s_app = new HPP(swfRoot);
		swfRoot.onLoad = function(){s_app.Load()};
		swfRoot.onUnload = function(){s_app.Unload()};
		swfRoot.OnModuleActivated = function(config){s_app.Activate(config)};
		swfRoot.OnModuleDeactivated = function(){return s_app.Deactivate()};
	}
	public function HPP() {
		mode = DistributedValue.Create("Hpp_Mode");
		decimals = DistributedValue.Create("Hpp_Decimals");
	}
	public function Load(){
		Hook();
	}
	public function Unload(){
	}
	public function Hook(){
		//Check that nametag component is loaded
		var healthbarComp = _global.com.Components.HealthBar;
		if (!healthbarComp){
			setTimeout(Delegate.create(this, Hook), 100);
			return
		}
		//Only hook once
		if (_global.com.fox.HPPHook) return
		_global.com.fox.HPPHook = true;
		
		// Percentage
		var f:Function = function ():Void {
			arguments.callee.base.apply(this, arguments);
			if (com.GameInterface.DistributedValueBase.GetDValue("Hpp_Mode") == 2){
				this.m_Text.htmlText = Math.round(100 * this.m_Current / this.m_Max) + "%";
			}
			else if (com.GameInterface.DistributedValueBase.GetDValue("Hpp_Mode") == 3){
				var number = Math.floor(this.m_Current) + " / " + Math.floor(this.m_Max)
				var multi = Math.pow(10, com.GameInterface.DistributedValueBase.GetDValue("Hpp_Decimals"))
				var percentage =  Math.round(100 * this.m_Current / this.m_Max * multi) / multi;
				this.m_Text.htmlText = number + "    " + percentage + " %";
			}
			
		}
		f.base = healthbarComp.prototype.UpdateStatText;
		healthbarComp.prototype.UpdateStatText = f;
		
	}
	
	public function Activate(config:Archive){
		mode.SetValue(config.FindEntry("Mode", 3));
		decimals.SetValue(config.FindEntry("Decimal", 0));
	}

	public function Deactivate():Archive{
		var config:Archive = new Archive();
		config.AddEntry("Mode", mode.GetValue());
		config.AddEntry("Decimal", decimals.GetValue());
		return config
	}
}