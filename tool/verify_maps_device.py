"""Native SDK smoke check. Stores redacted logs and screenshots for visual QA."""
import pathlib,re,subprocess,time,xml.etree.ElementTree as ET
from collections import Counter
from PIL import Image
out=pathlib.Path('build/maps-device-qa');out.mkdir(parents=True,exist_ok=True)
def adb(*args):return subprocess.check_output(['adb',*args])
adb('shell','am','force-stop','com.mazraa.driver')
# The emulator can finish booting before Wi-Fi is connected.
time.sleep(12)
adb('logcat','-c')
adb('shell','am','start','-n','com.mazraa.driver/.MainActivity')
for i in range(8):
    time.sleep(10)
    if i in (3,7):
        (out/f'map-{i}.png').write_bytes(adb('exec-out','screencap','-p'))
    if i in (2,4):
        adb('shell','uiautomator','dump','/sdcard/window.xml')
        tree=ET.fromstring(adb('shell','cat','/sdcard/window.xml'))
        for node in tree.iter('node'):
            if 'Retry map tiles' in (node.get('text','')+' '+node.get('content-desc','')):
                x1,y1,x2,y2=map(int,re.findall(r'\d+',node.get('bounds')))
                adb('shell','input','tap',str((x1+x2)//2),str((y1+y2)//2))
                print('Retried visible tiles after emulator network startup.')
                break
logs=adb('logcat','-d').decode(errors='replace')
logs=re.sub(r'AIza[\w-]{35}','[REDACTED_GOOGLE_KEY]',logs)
(out/'device.log').write_text(logs)
assert not re.search(r'Authorization failure|API key not found|API project is not authorized|FATAL EXCEPTION: main',logs,re.I), 'Native Maps authorization or startup failed; see redacted device log.'
adb('shell','uiautomator','dump','/sdcard/window.xml')
xml=adb('shell','cat','/sdcard/window.xml').decode(errors='replace')
(out/'window.xml').write_text(xml)
assert 'Mazraa map ready: OpenStreetMap' in logs, 'Working map surface was not observed.'
assert 'Retry map tiles' not in xml, 'Map tiles are still unavailable; review device.log.'
im=Image.open(out/'map-7.png').convert('RGB')
crop=im.crop((18,220,im.width-18,550))
colors=Counter(crop.getdata())
assert len(colors)>500 and colors.most_common(1)[0][1]/(crop.width*crop.height)<0.8, 'Map background is empty; tiles did not render.'
viewports=re.findall(r'MAP_VIEWPORT ([0-9.+-]+)\|([0-9.+-]+)\|([0-9.+-]+)',logs)
assert viewports, 'No rendered map viewport reported.'
lat,lon,zoom=map(float,viewports[-1])
assert 15.2 < lat < 15.5 and 44.1 < lon < 44.3 and 10 < zoom < 17, f'Unexpected trip viewport: {lat},{lon},zoom={zoom}'
print('OpenStreetMap viewport and rendered tile image checks passed on Android. Review map-7.png; Google SDK authorization was separately diagnosed.')
