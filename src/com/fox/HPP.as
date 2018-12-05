/*
* ...
* @author fox
*/
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Dynel;
import com.Utils.Archive;
import com.Utils.Colors;
import mx.utils.Delegate;

class com.fox.HPP {
	private var mode:DistributedValue;
	private var decimals:DistributedValue;
	private var self:DistributedValue;
	private var hostile:DistributedValue;
	
	public static function main(swfRoot:MovieClip):Void	{
		var s_app = new HPP(swfRoot);
		swfRoot.onLoad = function(){s_app.Load()};
		swfRoot.onUnload = function(){s_app.Unload()};
		swfRoot.OnModuleActivated = function(config){s_app.Activate(config)};
		swfRoot.OnModuleDeactivated = function(){return s_app.Deactivate()};
	}
	public function HPP() {
		mode = DistributedValue.Create("HPP_Mode");
		decimals = DistributedValue.Create("HPP_Decimals");
		self = DistributedValue.Create("HPP_OwnColor");
		hostile = DistributedValue.Create("HPP_HostileColor");
	}
	public function Load(){
		Hook();
		self.SignalChanged.Connect(Convert, this);
		hostile.SignalChanged.Connect(Convert, this);
	}
	public function Unload(){
		self.SignalChanged.Disconnect(Convert, this);
		hostile.SignalChanged.Disconnect(Convert, this);
	}
	public function Activate(config:Archive){
		mode.SetValue(config.FindEntry("Mode", 3));
		decimals.SetValue(config.FindEntry("Decimal", 0));
		self.SetValue(config.FindEntry("Self", 0x20FF8A));
		hostile.SetValue(config.FindEntry("Hostile", 0xff4646));
	}
	public function Deactivate():Archive{
		var config:Archive = new Archive();
		config.AddEntry("Mode", mode.GetValue());
		config.AddEntry("Decimal", decimals.GetValue());
		config.AddEntry("Self", self.GetValue());
		config.AddEntry("Hostile", hostile.GetValue());
		return config
	}
	private function Convert(dv:DistributedValue){
		var val = dv.GetValue();
		if (val == undefined || val == false){// Can be 0
			if (dv.GetName() == "HPP_OwnColor"){
				dv.SetValue(0x20FF8A);
			}else{
				dv.SetValue(0xff4646);
			}
		}else{
			if (dv.GetName() == "HPP_OwnColor"){
				Colors.ApplyColor(_root.playerinfo.m_HealthBar.m_Bar.m_MeterFriend, dv.GetValue());
			}else{
				Colors.ApplyColor(_root.targetinfo.m_HealthBar.m_Bar.m_MeterEnemy, dv.GetValue());
				//target info is always available,just hidden
			}
		}
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
			if (com.GameInterface.DistributedValueBase.GetDValue("HPP_Mode") == 2){
				var multi = Math.pow(10, com.GameInterface.DistributedValueBase.GetDValue("HPP_Decimals"))
				var percentage =  Math.round(100 * this.m_Current / this.m_Max * multi) / multi;
				this.m_Text.htmlText = percentage + " %";
			}
			else if (com.GameInterface.DistributedValueBase.GetDValue("HPP_Mode") == 3){
				var number = Math.floor(this.m_Current) + " / " + Math.floor(this.m_Max)
				var multi = Math.pow(10, com.GameInterface.DistributedValueBase.GetDValue("HPP_Decimals"))
				var percentage =  Math.round(100 * this.m_Current / this.m_Max * multi) / multi;
				this.m_Text.htmlText = number + "    " + percentage + " %";
			}
		}
		f.base = healthbarComp.prototype.UpdateStatText;
		healthbarComp.prototype.UpdateStatText = f;
		
		// Color
		f = function (dynel:Dynel):Void {
			arguments.callee.base.apply(this, arguments);
			if (dynel == undefined || !this.m_ShowText)	{
				return;
			}
			if (dynel.GetID().Equal(com.GameInterface.Game.Character.GetClientCharacter().GetID())){
				this.m_Bar.m_Red._visible = false;
				Colors.ApplyColor(this.m_Bar.m_MeterFriend, com.GameInterface.DistributedValueBase.GetDValue("HPP_OwnColor"));
			}else{
				this.m_Bar.m_Red._visible = false;
				Colors.ApplyColor(this.m_Bar.m_MeterEnemy, com.GameInterface.DistributedValueBase.GetDValue("HPP_HostileColor"));
			}
		}
		f.base = healthbarComp.prototype.SetDynel;
		healthbarComp.prototype.SetDynel = f;
	}
}