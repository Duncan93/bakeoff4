import java.util.ArrayList;
import java.util.Collections;
import ketai.sensors.*;
import android.media.AudioRecord;
import android.media.AudioFormat;
import android.media.MediaRecorder;

//import ddf.minim.AudioInput;
//import ddf.minim.AudioOutput;
//import ddf.minim.Minim;
//import ddf.minim.analysis.FFT;

//Minim minim;
//AudioInput in;
//FFT fft;
//AudioOutput out;
//float smoothFFT[] = new float[512];

int       RECORDER_SAMPLERATE = 44100;
int       MAX_FREQ = RECORDER_SAMPLERATE/2;
final int RECORDER_CHANNELS = AudioFormat.CHANNEL_IN_MONO;
final int RECORDER_AUDIO_ENCODING = AudioFormat.ENCODING_PCM_16BIT;
final int PEAK_THRESH = 20;

short[]     buffer           = null;
int         bufferReadResult = 0;
AudioRecord audioRecord      = null;
boolean     aRecStarted      = false;
int         bufferSize       = 2048;
int         minBufferSize    = 0;
float       volume           = 0;
FFT         fft              = null;
float[]     fftRealArray     = null;
int         mainFreq         = 0;

float       drawScaleH       = 4.5; // TODO: calculate the drawing scales
float       drawScaleW       = 1.0; // TODO: calculate the drawing scales
int         drawStepW        = 2;   // display only every Nth freq value
float       maxFreqToDraw    = 2500; // max frequency to represent graphically
int         drawBaseLine     = 0;

KetaiSensor sensor;

float cursorX, cursorY;
float light = 0;
float currentX = 0, currentY = 0, currentZ = 0;

//float[][] ranges = {{0.5723908259999999, 5.005203160000001}, {3.4840269510000006, 13.588887519}, {3.1520270440000004, 14.0012884}, {2.805375906000001, 14.149332236}, {2.767587105, 9.899312491}, {3.1098925469999994, 14.903788454999999}, {-0.23689376699999976, 12.276584041}, {1.6040440179999997, 11.564569256}, {0.4452463849999999, 5.319730015}, {0.289632095, 6.380806441}, {-0.03243759999999973, 9.294098794}, {-0.29874521700000045, 9.513843159}, {-0.2306303320000005, 9.884628934}, {0.406830456, 4.067993814}, {0.17984301400000025, 5.58556584}, {0.0017502560000000056, 3.614785372}, {-0.08284749000000002, 2.393275324}, {-0.4956923240000002, 4.124165984}, {-0.36332115399999987, 2.851613988}, {-0.04969513299999995, 1.548765903}, {0.027612917000000015, 1.133144987}, {-0.08884063900000005, 1.160580197}, {-0.045465937999999984, 0.887656602}, {-0.033714407, 0.839322613}, {-0.07528206300000001, 0.8216339269999999}, {-0.08971373599999999, 0.759021156}, {-0.11993536399999999, 0.759957634}, {-0.08622986799999999, 0.699090506}, {-0.06193036499999999, 0.6258483029999999}, {-0.01848333200000002, 0.544470284}, {-0.024507632999999973, 0.512416041}, {-0.02830052600000002, 0.5120888140000001}, {-0.020323091000000015, 0.481019339}, {-0.023102280000000003, 0.46500948200000003}, {-0.023360349000000002, 0.453824491}, {-0.012387598, 0.4242293}, {0.0005078720000000203, 0.399508996}, {0.0016065269999999965, 0.392405299}, {-0.0028431409999999935, 0.374360757}, {0.007418247999999988, 0.383686416}, {0.0019279050000000075, 0.370818539}, {0.007890698000000002, 0.360614372}, {0.01144007700000002, 0.319062351}, {0.002662545999999988, 0.316808164}, {0.00025191300000002026, 0.315575625}, {-0.0026547140000000025, 0.299351516}, {-0.0008183069999999903, 0.29565458899999997}, {-0.0013252229999999865, 0.286188445}, {0.0028744990000000026, 0.282311917}, {0.0007123199999999885, 0.285873916}, {0.0007897300000000163, 0.280743418}, {0.0005588470000000012, 0.267916853}, {0.001719955000000023, 0.27331727699999997}, {0.004834593999999998, 0.26913068799999995}, {0.007576770999999982, 0.263111437}, {0.00021380900000000924, 0.285549499}, {0.008126392999999982, 0.27937832900000004}, {0.013962028999999987, 0.269311709}, {0.00797776900000001, 0.244295249}, {0.01025647099999999, 0.251657323}, {-0.011308604, 0.302965844}, {-0.008137469000000008, 0.296018063}, {-0.005517444999999982, 0.270118357}, {-0.001984882999999993, 0.243522609}, {0.008301546000000007, 0.236190994}, {0.012887760999999998, 0.256557443}, {0.017319266, 0.25612191}, {0.004350190000000004, 0.240576136}, {0.0036207340000000005, 0.22731586399999998}, {-0.005668603999999994, 0.210707024}, {4.385899999999332e-05, 0.211042931}, {0.0012737889999999974, 0.208908439}, {-0.0005111379999999943, 0.204585126}, {-0.003418832999999996, 0.20815092699999999}, {-0.006279533999999989, 0.217861494}, {-0.0011736670000000032, 0.199576657}, {-0.0016399599999999959, 0.20435276}, {-0.012310655000000004, 0.224140951}, {-0.010326795, 0.214349829}, {-0.006698514000000003, 0.213612352}, {-0.007352458999999992, 0.21344264899999998}, {-0.006473907000000001, 0.215948477}, {-0.011610829000000003, 0.230905325}, {-0.003874938999999994, 0.214913727}, {0.001978305999999999, 0.20621224999999999}, {0.003051333999999989, 0.205318744}, {0.008423739, 0.195469821}, {0.003001861999999994, 0.187614966}, {0.005182407, 0.176798575}, {0.0026087409999999978, 0.167235025}, {0.002542961999999996, 0.166345964}, {0.0034687109999999993, 0.17878981300000002}, {0.009337052000000012, 0.176504886}, {0.005918040999999999, 0.17186035900000002}, {0.004928648999999993, 0.17010650900000002}, {-0.003436952000000007, 0.178064972}, {-0.006748119999999996, 0.175263462}, {-0.006531888, 0.169274394}, {-0.004923916, 0.162200062}, {-0.003602872000000007, 0.164840806}, {-0.0021306170000000013, 0.153675639}, {-0.0052081220000000095, 0.149607622}, {-0.006484983999999999, 0.142569446}, {-0.0033198680000000036, 0.138046266}, {0.00023741899999998872, 0.132039139}, {0.001160377000000004, 0.131393667}, {-0.0007920600000000111, 0.13037583}, {-0.002206261000000001, 0.13759217899999998}, {-0.0035455779999999937, 0.135201612}, {-0.004252192000000002, 0.138230268}, {8.025200000000288e-05, 0.132661328}, {0.0006971409999999983, 0.124293531}, {0.0023366260000000014, 0.121347184}, {0.0010043950000000051, 0.125948399}, {-0.0017323520000000064, 0.135124806}, {-0.0027784899999999946, 0.144956846}, {-0.0012155940000000004, 0.14158827400000001}, {0.002962123000000011, 0.129411259}, {-0.0008991039999999978, 0.14245691}, {0.0023378729999999903, 0.151183757}, {0.0017872619999999978, 0.162777842}, {-0.011033825999999997, 0.18639592}, {-0.00944250599999999, 0.188402764}, {-0.007650319000000003, 0.17221492900000002}, {-0.0028887840000000053, 0.16200981}, {0.0016040499999999958, 0.1329677}, {0.001577971999999997, 0.118435738}, {0.0011466629999999992, 0.11470825100000001}, {0.0015307910000000036, 0.117397025}, {0.0028250309999999987, 0.11172995899999999}, {0.002452998000000005, 0.112876206}, {0.0017177440000000002, 0.117598006}, {0.0018534590000000017, 0.124294867}, {-0.0005907659999999926, 0.12939776}, {-0.0016060209999999991, 0.12673558899999998}, {-0.0010084409999999919, 0.12444275099999999}, {0.0026526159999999965, 0.116118742}, {-0.0002033909999999972, 0.104605801}, {-0.0015686130000000034, 0.117696085}, {-0.003687085999999992, 0.123823912}, {-0.0053413579999999974, 0.11935299399999999}, {-0.0026440000000000005, 0.10925000400000001}, {-0.0001491800000000057, 0.10456104}, {-0.00036259800000000564, 0.102387698}, {-0.001602381, 0.101271125}, {-0.0029806860000000032, 0.10126001200000001}, {-0.001706197999999999, 0.10188256000000001}, {-0.002075582999999999, 0.099885737}, {-0.0007501609999999992, 0.100118555}, {-0.0006564699999999993, 0.098618072}, {-0.001204025999999997, 0.098279402}, {-0.002266703000000002, 0.097933245}, {-0.0015069570000000032, 0.098412021}, {-0.0006990690000000035, 0.09934764900000001}, {-0.00045079199999999847, 0.098490314}, {-7.141000000002173e-06, 0.098321437}, {-0.0006523699999999993, 0.096280582}, {-0.00025638499999999786, 0.097033999}, {-0.0006582790000000047, 0.095839867}, {-0.0018965280000000015, 0.095421262}, {-0.002056697000000003, 0.09447356500000001}, {-0.0020701490000000003, 0.09318923500000001}, {-0.0020628999999999995, 0.092936362}, {-0.0015121000000000023, 0.093477274}, {-0.0016204120000000016, 0.093320684}, {-0.0023965930000000024, 0.092241775}, {-0.0023939810000000034, 0.092947319}, {-0.002073830999999998, 0.092303837}, {-0.0022737749999999987, 0.09170315100000001}, {-0.0021576040000000005, 0.091658934}, {-0.0019442900000000013, 0.09161538}, {-0.0018907239999999964, 0.09129703}, {-0.0009093069999999981, 0.090418451}, {-0.0004366709999999996, 0.089854341}, {-0.0017919419999999978, 0.091388162}, {-0.002196194999999998, 0.092104355}, {-0.0013592990000000013, 0.092729217}, {-0.0001901259999999988, 0.093746116}, {0.001516338000000006, 0.091461898}, {0.0009968709999999964, 0.091152363}, {-0.0017150369999999956, 0.095707015}, {-0.0030879300000000026, 0.09792859}, {-0.0037512329999999997, 0.097362049}, {-0.0018813339999999984, 0.090362868}, {-0.0007485090000000014, 0.08575490499999999}, {-0.0005862449999999991, 0.085989727}, {-0.0025718900000000003, 0.086435558}, {-0.002870409999999997, 0.08658521}, {-0.0024221000000000034, 0.08694563}, {-0.002038037999999999, 0.08568700800000001}, {-0.0018653000000000003, 0.08923072}, {-0.0020077710000000054, 0.087592771}, {-0.001563015000000001, 0.085007923}, {-0.0023191300000000026, 0.0896135}, {-0.0018528099999999964, 0.086488548}, {-0.0014980559999999976, 0.083446518}, {-0.002126033999999999, 0.08669766}, {-0.002298080000000001, 0.084944624}, {-0.002262335000000004, 0.083408043}, {-0.0031209399999999957, 0.08427111200000001}, {-0.0023957130000000007, 0.08394807500000001}, {-0.0021037840000000044, 0.083433286}, {-0.0020511859999999965, 0.08311449}, {-0.0019929849999999957, 0.082566857}, {-0.0012450050000000004, 0.08250479699999999}, {-0.0011666590000000004, 0.082337047}, {-0.0016285369999999993, 0.082464865}, {-0.0012879420000000003, 0.082595906}, {-0.0016721209999999986, 0.083202043}, {-0.0021704989999999993, 0.082800601}, {-0.0022157349999999965, 0.081991145}, {-0.0021485450000000017, 0.082063723}, {-0.001960194999999998, 0.081683059}, {-0.0017396000000000009, 0.08122354200000001}, {-0.001769412000000005, 0.08091509}, {-0.0020622939999999992, 0.08088071}, {-0.0021537690000000068, 0.081023431}, {-0.0021963350000000006, 0.080722767}, {-0.002152652000000005, 0.080646836}, {-0.0022623649999999954, 0.080034661}, {-0.0018323080000000047, 0.080418696}, {-0.002533297000000004, 0.080158697}, {-0.0021700129999999984, 0.080300777}, {-0.0022980699999999993, 0.080319074}, {-0.0022981470000000004, 0.079937625}, {-0.001988066999999996, 0.079564545}, {-0.0020202380000000006, 0.07956603400000001}, {-0.002184138000000002, 0.079539362}, {-0.0021974560000000004, 0.079467438}, {-0.0022252619999999987, 0.07951551200000001}, {-0.0022096760000000007, 0.07941904999999999}, {-0.0021608510000000053, 0.079170535}, {-0.002198257000000002, 0.079163169}, {-0.002116031999999997, 0.07912314000000001}, {-0.0020913330000000008, 0.079037169}, {-0.002188822, 0.079021424}, {-0.002211679000000001, 0.078918757}, {-0.0022193449999999976, 0.078863797}, {-0.0021114110000000005, 0.07884925500000001}, {-0.0021602220000000033, 0.078784546}, {-0.002144433000000001, 0.078689407}, {-0.0021362419999999965, 0.078696688}, {-0.0021434130000000037, 0.078656547}, {-0.0021337960000000003, 0.07861267799999999}, {-0.0021295980000000034, 0.07854650199999999}, {-0.0021434770000000047, 0.078535623}, {-0.0021529110000000004, 0.07852804699999999}, {-0.002158855000000001, 0.078460469}, {-0.002171993000000004, 0.078482561}, {-0.002146323999999998, 0.078429002}, {-0.0021435150000000056, 0.07841748700000001}, {-0.002173904999999997, 0.07839278899999999}, {-0.002148733, 0.078363337}, {-0.0021780830000000043, 0.078350099}, {-0.0021644479999999994, 0.078379192}, {-0.0021713419999999997, 0.07834713600000001}, {-0.0021299070000000003, 0.078351831}, {-0.0021299070000000003, 0.078351831}, {-0.0021299070000000003, 0.078351831}, {-0.0021299070000000003, 0.078351831}, {-0.0021299070000000003, 0.078351831}};
float[][] ranges = {{0,0}};

private class Target
{
  int target = 0;
  int action = 0;
  boolean selected = false;
}

int trialCount = 5; //this will be set higher for the bakeoff
int trialIndex = 0;
ArrayList<Target> targets = new ArrayList<Target>();
   
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false;
int countDownTimerWait = 0;

void setupAudio()
{
  drawBaseLine = height-150;
  minBufferSize = AudioRecord.getMinBufferSize(RECORDER_SAMPLERATE,RECORDER_CHANNELS,RECORDER_AUDIO_ENCODING);
  // if we are working with the android emulator, getMinBufferSize() does not work
  // and the only samplig rate we can use is 8000Hz
  if (minBufferSize == AudioRecord.ERROR_BAD_VALUE)  {
    RECORDER_SAMPLERATE = 8000; // forced by the android emulator
    MAX_FREQ = RECORDER_SAMPLERATE/2;
    bufferSize =  getHigherP2(RECORDER_SAMPLERATE);// buffer size must be power of 2!!!
    // the buffer size determines the analysis frequency at: RECORDER_SAMPLERATE/bufferSize
    // this might make trouble if there is not enough computation power to record and analyze
    // a frequency. In the other hand, if the buffer size is too small AudioRecord will not initialize
  } else bufferSize = minBufferSize;
  
  buffer = new short[bufferSize];
  // use the mic with Auto Gain Control turned off!
  audioRecord = new AudioRecord( MediaRecorder.AudioSource.VOICE_RECOGNITION, RECORDER_SAMPLERATE,
                                 RECORDER_CHANNELS,RECORDER_AUDIO_ENCODING, bufferSize);
 
  //audioRecord = new AudioRecord( MediaRecorder.AudioSource.MIC, RECORDER_SAMPLERATE,
   //                              RECORDER_CHANNELS,RECORDER_AUDIO_ENCODING, bufferSize);
  if ((audioRecord != null) && (audioRecord.getState() == AudioRecord.STATE_INITIALIZED)) {
    try {
      // this throws an exception with some combinations
      // of RECORDER_SAMPLERATE and bufferSize 
      audioRecord.startRecording(); 
      aRecStarted = true;
    }
    catch (Exception e) {
      aRecStarted = false;
    }
    
    if (aRecStarted) {
        bufferReadResult = audioRecord.read(buffer, 0, bufferSize);
        // compute nearest higher power of two
       bufferReadResult = getHigherP2(bufferReadResult);
        fft = new FFT(bufferReadResult, RECORDER_SAMPLERATE);
        fftRealArray = new float[bufferReadResult]; 
        drawScaleW = drawScaleW*(float)width/(float)fft.freqToIndex(maxFreqToDraw);
    }
  }
}

void setup() {
  size(480,800); //you can change this to be fullscreen
  frameRate(60);
  sensor = new KetaiSensor(this);
  sensor.start();
  orientation(PORTRAIT);
  setupAudio();
  
  // sound code
  //minim = new Minim(this);
  //in = minim.getLineIn(Minim.STEREO, 512, 44100);
  //fft = new FFT(in.bufferSize(), in.sampleRate());

  rectMode(CENTER);
  textFont(createFont("Arial", 20));
  textAlign(CENTER);
  
  for (int i=0;i<trialCount;i++)  //don't change this!
  {
    Target t = new Target();
    t.target = ((int)random(1000))%4;
    t.action = ((int)random(1000))%2;
    targets.add(t);
    println("created target with " + t.target + "," + t.action);
  }
  
  Collections.shuffle(targets); // randomize the order of the button;
}

void determineFill(int index)
{
  if (targets.get(trialIndex).target==index && targets.get(index).selected) fill(0,255,0);
  else if (targets.get(trialIndex).target==index) fill(0,0,255);
  else if (targets.get(index).selected) fill(0,255,255); 
  else fill(180,180,180);
}

boolean heardKnock()
{
  for (int i = 0; i < 512; i++) {
    float band = fft.getBand(i);
    int rangeIndex;
    if (i < ranges.length) rangeIndex = i;
    else rangeIndex = ranges.length-1;
    // check whether band exceeds acceptable range
    if (band < ranges[rangeIndex][0] || band > ranges[rangeIndex][1]) return false; 
  }
  return true;
}

void stop() {
  audioRecord.stop();
  audioRecord.release();
}

// compute nearest higher power of two
// see: graphics.stanford.edu/~seander/bithacks.html
int getHigherP2(int val)
{
  val--;
  val |= val >> 1;
  val |= val >> 2;
  val |= val >> 8;
  val |= val >> 16;
  val++;
  return(val);
}

void draw() {

  background(80); //background is light grey
  noStroke(); //no stroke
  
  countDownTimerWait--;
  
  if (startTime == 0)
    startTime = millis();
  
  if (trialIndex==targets.size() && !userDone)
  {
    userDone=true;
    finishTime = millis();
  }
  
  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, 50);
    text("User took " + nfc((finishTime-startTime)/1000f/trialCount,1) + " sec per target", width/2, 150);
    return;
  }
  
  //fft.forward(in.left);
  //if (heardKnock()) System.out.println("knock");
  
  rectMode(CENTER);
  // Draw targets (mapping to index is: 0 --> left, 1 --> right, 2 --> top, 3 --> bottom)
  // draw left target
  determineFill(0);
  rect(50, 500, 100, 300);
  // draw right target
  determineFill(1);
  rect(175, 500, 100, 300);
  // draw top target
  determineFill(2);
  rect(width/2, height/4, 300, 100);
  // draw bottom target
  determineFill(3);
  rect(width/2, height/4 + 125, 300, 100);

  // respond to light sensor (remove this)
  if (light>20)
    fill(180,0,0);
  else
    fill(255,0,0);
  // draw cursor at mouse
  //ellipse(cursorX,cursorY,50,50);
 
  fill(255);//white
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, 50);
  text("Target #" + (targets.get(trialIndex).target)+1, width/2, 100);
  
  //// handle action instructions
  //if (targets.get(trialIndex).action==0){}
  //  //text("UP", width/2, 150);
  //else{}
  //   //text("DOWN", width/2, 150);
}
  
/*
Accelerometers provide a velocity, but don't indicate in what direction something went
Need to use Kalman Filter or thresholded double integration to find position.
*/

private class Move
{
  float value;
  String axis; 
  
  //public void Move(float value, String axis)
  //{
  //  this.value = value;
  //  this.axis = axis;
  //}
}

ArrayList<Move> moves = new ArrayList<Move>();

void addMove(float value, String axis)
{
  Move move = new Move();
  move.value = value;
  move.axis = axis;
  moves.add(move);
}

void deselectTargets()
{
  // remove all selected states
  for (int i = 0; i < 4; i++) targets.get(i).selected = false;
}

/* 
Looks at the moves thus far and determines which target is selected
This version just looks at the two previous moves
(mapping to index is: 0 --> left, 1 --> right, 2 --> top, 3 --> bottom)
*/
void determineSelected()
{
  if (moves.size() == 1)
  {
    // select right
    if (moves.get(0).axis.equals("x")) targets.get(1).selected = true;
    // select bottom
    else targets.get(3).selected = true;
  }
  else
  {
    Move current = moves.get(moves.size()-1);
    Move previous = moves.get(moves.size()-2);
    // last two moves in same direction
    if (current.axis.equals(previous.axis))
    {
      // if left selected, movement selects right
      if (current.axis.equals("x") && targets.get(0).selected)
      {
        deselectTargets();
        targets.get(1).selected = true;
      }
      // if right selected, movement selects left
      else if (current.axis.equals("x") && targets.get(1).selected)
      {
        deselectTargets();
        targets.get(0).selected = true;
      }
      // if top selected, movement selects bottom
      if (current.axis.equals("y") && targets.get(2).selected)
      {
        deselectTargets();
        targets.get(3).selected = true;
      }
      // if bottom selected, movement selects top
      else if (current.axis.equals("y") && targets.get(3).selected)
      {
        deselectTargets();
        targets.get(2).selected = true;
      }
    }
    else // (reset)
    {
      // select right
      if (current.axis.equals("x")) 
      {
        deselectTargets();
        targets.get(1).selected = true;
      }
      // select bottom
      else 
      {
        deselectTargets();
        targets.get(3).selected = true;
      }
    }
  }
}

void onAccelerometerEvent(float x, float y, float z)
{
    if (moves.size() == 0)
    {
      if (y > 1)
      {
        //System.out.println("y "+y); 
        addMove(y, "y");
        determineSelected(); // allow diagonal movement?
      }
      else if (x > 1)
      {
        //System.out.println("x "+x); 
        addMove(y, "y");
        determineSelected();
      }
    }
    else
    {
      // need a lot of error checking because accelerometer events get triggered multiple times with the same value
      // y-axis case
      //* need to account for empty arraylist
      if (y > 1 && (!moves.get(moves.size()-1).axis.equals("y") || moves.get(moves.size()-1).value != y))
      {
        //System.out.println(moves.size());
        //System.out.println("y "+y); 
        addMove(y, "y");
        determineSelected(); // allow diagonal movement?
      }
      else if (x > 1 && (!moves.get(moves.size()-1).axis.equals("x") || moves.get(moves.size()-1).value != x))
      {
        //System.out.println("x "+x); 
        addMove(x, "x");
        determineSelected();
      }
    }
    
    
    
    
  //}
  
  if (userDone)
    return;
    
  // remove this
  if (light>20) //only update cursor, if light is low
  {
    cursorX = 300+x*40; //cented to window and scaled
    cursorY = 300-y*40; //cented to window and scaled
  }
  
  Target t = targets.get(trialIndex);
  
  
  // remove this
  if (light<=20 && abs(z-9.8)>4 && countDownTimerWait<0) //possible hit event
  {
    if (hitTest()==t.target)//check if it is the right target
    {
      println(z-9.8);
      if (((z-9.8)>4 && t.action==0) || ((z-9.8)<-4 && t.action==1))
      {
        println("Right target, right z direction! " + hitTest());
        trialIndex++; //next trial!
        currentX = 0;
        currentY = 0;
        currentZ = 0;
        moves.clear();
        deselectTargets();
      }
      else
        println("right target, wrong z direction!");
        
      countDownTimerWait=30; //wait 0.5 sec before allowing next trial
    }
    else
      println("Missed target! " + hitTest()); //no recording errors this bakeoff.
  }
}

int hitTest() 
{
   for (int i=0;i<4;i++)
      if (dist(300,i*150+100,cursorX,cursorY)<100)
        return i;
 
    return -1;
}

  
void onLightEvent(float v) //this just updates the light value
{
  light = v;
}