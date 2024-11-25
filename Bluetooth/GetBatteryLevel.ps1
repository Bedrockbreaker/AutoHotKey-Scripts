Add-Type -AssemblyName 'Windows.Devices.Bluetooth'

$device = [Windows.Devices.Bluetooth.BluetoothLEDevice]::FromBluetoothAddressAsync("").GetAwaiter().GetResult()
$gatt = $device.GetGattServicesAsync().GetAwaiter().GetResult()

foreach ($service in $gatt.Services) {
	foreach ($char in $service.GetCharacteristicsAsync().GetAwaiter().getResult().Characteristics) {
		if ($char.CharacteristicProperties -eq "Read") {
			$batteryData = $char.ReadValueAsync().GetAwaiter().GetResult()
			$batteryData
		}
	}
}