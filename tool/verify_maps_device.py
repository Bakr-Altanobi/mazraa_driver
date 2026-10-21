"""Native SDK smoke check. Stores redacted logs and screenshots for visual QA."""
import pathlib,re,subprocess,time
out=pathlib.Path('build/maps-device-qa');out.mkdir(parents=True,exist_ok=True)
def adb(*args):return subprocess.check_output(['adb',*args])
adb('logcat','-c')
adb('shell','am','start','-n','com.mazraa.driver/.MainActivity')
for i in range(6):
    time.sleep(10)
    if i in (2,5):
        (out/f'map-{i}.png').write_bytes(adb('exec-out','screencap','-p'))
logs=adb('logcat','-d').decode(errors='replace')
logs=re.sub(r'AIza[\w-]{35}','[REDACTED_GOOGLE_KEY]',logs)
(out/'device.log').write_text(logs)
assert not re.search(r'Authorization failure|API key not found|API project is not authorized|FATAL EXCEPTION: main',logs,re.I), 'Native Maps authorization or startup failed; see redacted device log.'
adb('shell','uiautomator','dump','/sdcard/window.xml')
xml=adb('shell','cat','/sdcard/window.xml').decode(errors='replace')
(out/'window.xml').write_text(xml)
assert 'Mazraa map ready: OpenStreetMap' in logs, 'Working map surface was not observed.'
print('OpenStreetMap surface started on Android. Review map screenshots to confirm tile rendering; Google SDK authorization was separately diagnosed.')
