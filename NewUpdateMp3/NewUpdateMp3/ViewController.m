//
//  ViewController.m
//  UploadMp3
//
//  Created by 嘿o大远 on 2017/7/27.
//  Copyright © 2017年 嘿o大远. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "lame.h"
#import <AFNetworking.h>

@interface ViewController ()<
AVAudioPlayerDelegate,//播放
AVAudioRecorderDelegate,//录音
UIAlertViewDelegate
>
@property (weak, nonatomic) IBOutlet UILabel *volume;
@property (nonatomic, strong) NSString *strCAFPath;
@property (nonatomic, strong) NSString *strMp3Path;

@property (nonatomic, strong) AVAudioPlayer *avPlayer;
@property (nonatomic, strong) AVAudioRecorder *avRecorder;

@property (nonatomic, strong) NSString *lastRecordFileName;

@property (nonatomic, strong) NSString *updateMp3File;
@property (nonatomic, strong) NSString *upFileName;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSDateFormatter *folderNameFormatter = [[NSDateFormatter alloc] init];
    [folderNameFormatter setDateFormat:@"yyyyMMddhhmmss"];
    NSString *folderName = [folderNameFormatter stringFromDate:[NSDate date]] ;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSLog(@"documentsDirectory:%@",documentsDirectory);
    NSString *folderPath = [documentsDirectory stringByAppendingPathComponent:folderName];
    NSLog(@"folderPath:%@",folderPath);
    
    _strCAFPath = [[NSString alloc] initWithFormat:@"%@/%@",documentsDirectory,@"CAF"];
    _strMp3Path = [[NSString alloc] initWithFormat:@"%@/%@",documentsDirectory,@"Mp3"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //创建两个文件夹
    [fileManager createDirectoryAtPath:_strCAFPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createDirectoryAtPath:_strMp3Path withIntermediateDirectories:YES attributes:nil error:nil];
    
}
//开始录音
- (IBAction)luyin:(id)sender {
    NSDateFormatter *fileNameFormatter = [[NSDateFormatter alloc] init];
    [fileNameFormatter setDateFormat:@"yyyyMMddhhmmss"];
    NSString *fileName = [fileNameFormatter stringFromDate:[NSDate date]];
    
    fileName = [fileName stringByAppendingString:@".caf"];
    NSString *cafFilePath = [_strCAFPath stringByAppendingPathComponent:fileName];
    
    NSURL *cafURL = [NSURL fileURLWithPath:cafFilePath];
    
    NSError *error;
    NSLog(@"开始录音____cafURL:%@" ,cafURL);
    
    NSDictionary *recordFileSettings = [NSDictionary
                                        dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:AVAudioQualityMin],
                                        AVEncoderAudioQualityKey,
                                        [NSNumber numberWithInt:16],
                                        AVEncoderBitRateKey,
                                        [NSNumber numberWithInt: 2],
                                        AVNumberOfChannelsKey,
                                        [NSNumber numberWithFloat:44100.0],
                                        AVSampleRateKey,
                                        nil];
    @try {
        if (!_avPlayer) {
            _avRecorder = [[AVAudioRecorder alloc] initWithURL:cafURL settings:recordFileSettings error:&error];
        }else {
            if ([_avRecorder isRecording]) {
                [_avRecorder stop];
            }
            _avRecorder=Nil;
            _avRecorder = [[AVAudioRecorder alloc] initWithURL:cafURL settings:recordFileSettings error:&error];
        }
        
        if (_avRecorder) {
            [_avRecorder prepareToRecord];
            _avRecorder.meteringEnabled = YES;
            
            [_avRecorder record];
            NSLog(@"_avRecorder recording");
            self.lastRecordFileName=fileName;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        NSLog(@"%@",[error description]);
    }
    
    
    
}
//停止
- (IBAction)stop:(id)sender {
    if (_avRecorder) {
        NSError *error=nil;
        NSLog(@"___结束录音");
        @try {
            [_avRecorder stop];
            _avRecorder=Nil;
            [self toMp3:self.lastRecordFileName];
            
        }
        @catch (NSException *exception) {
            NSLog(@"%@",[exception description]);
            
        }
        @finally {
            NSLog(@"%@",[error description]);
        }
    }
    
}
//播放
- (IBAction)play:(id)sender {
    if (!_updateMp3File) {
        NSLog(@"当前未录音");
        return;
    }
    NSError *error;
    _avPlayer= [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:_updateMp3File] error:&error];
    [_avPlayer play];
}
//上传
- (IBAction)update:(id)sender {
    if (!_updateMp3File) {
        NSLog(@"当前未录音");
        return;
    }
    NSString *bundle =  [[NSBundle mainBundle] pathForResource:@"11" ofType:@"mp3"];
    NSURL *fileUrl = [NSURL URLWithString:bundle];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [AFHTTPResponseSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    /** 设置content-type  */
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/plain", @"text/html", nil];
    //TODO:URL写自己服务器的
    NSString *url = @"";
    
    [manager POST:url parameters:@{@"uploadType":@2} constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSLog(@"%@",_updateMp3File);
        NSData *data = [NSData dataWithContentsOfFile:_updateMp3File];
        [formData appendPartWithFileData:data name:@"file" fileName:_upFileName mimeType:@"mp3"];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        float progress = 1.0 * uploadProgress.completedUnitCount / uploadProgress.totalUnitCount;
        NSLog(@"上传进度-----   %f",progress);
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"上传成功 %@",responseObject);
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"上传失败 %@",error);
        
    }];
    
}

//转换成MP3
- (void)toMp3:(NSString*)cafFileName
{
    NSString *cafFilePath =[_strCAFPath stringByAppendingPathComponent:cafFileName];
    
    NSDateFormatter *fileNameFormat=[[NSDateFormatter alloc] init];
    [fileNameFormat setDateFormat:@"yyyyMMddhhmmss"];
    NSString *mp3FileName = [fileNameFormat stringFromDate:[NSDate date]];
    mp3FileName = [mp3FileName stringByAppendingString:@".mp3"];
    NSString *mp3FilePath = [_strMp3Path stringByAppendingPathComponent:mp3FileName];
    _updateMp3File = mp3FilePath;
    _upFileName = mp3FileName;
    
    @try {
        long read; int write;
        FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");//被转换的文件
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");//转换后文件的存放位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 44100);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, (int)read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
        
    } @catch (NSException *exception) {
        
        NSLog(@"%@",[exception description]);
    }
    @finally {
        
        NSLog(@"mp3___%@",_strMp3Path);
        
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
