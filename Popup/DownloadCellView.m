
#import "Utilities.h"
#import "DownloadCellView.h"

@implementation DownloadCellView

-(void)dealloc
{
    [iconLoader cancel];
    [self stopObservingDownload];
}

-(void)startObservingDownload
{
    [_download addObserver:self forKeyPath:@"status" options:0 context:nil];
    [_download addObserver:self forKeyPath:@"progress" options:0 context:nil];
}

-(void)stopObservingDownload
{
    [_download removeObserver:self forKeyPath:@"status"];
    [_download removeObserver:self forKeyPath:@"progress"];
}

-(void)setDownload:(PutIODownload *)download
{
    [self stopObservingDownload];
    _download = download;
    self.textField.stringValue = download.putioFile.name;
    [progressBar startAnimation:self];
    [self updateStatus];
    [self loadIcon];
    [self startObservingDownload];
}

-(PutIODownload *)download
{
    return _download;
}

#pragma mark - Displaying status

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self updateStatus];
}

-(void)updateStatus
{
    PutIODownload *download = _download;
    [progressBar setHidden:!(download.status == PutIODownloadStatusDownloading)];
    [statusLabelConstraint setConstant:((download.status == PutIODownloadStatusDownloading) ? 0 : -8)];
    [textLabelConstraint setConstant:((download.status == PutIODownloadStatusDownloading) ? 3 : 12)];
    if(download.status == PutIODownloadStatusDownloading){
        [pauseResumeButton setImage:[NSImage imageNamed:@"stopImage.png"]];
        [pauseResumeButton setHidden:NO];
    }else if(download.status == PutIODownloadStatusPaused || download.status == PutIODownloadStatusFailed){
        [pauseResumeButton setImage:[NSImage imageNamed:@"resumeImage.png"]];
        [pauseResumeButton setHidden:NO];
    }else{
        [pauseResumeButton setHidden:YES];
    }

    NSString *statusString = download.localizedStatus;
    NSString *sizeReceivedString = unitStringFromBytes(download.receivedSize);
    NSString *sizeTotalString = unitStringFromBytes(download.totalSize);
    NSString *sizesString = [NSString stringWithFormat:@"%@ of %@", sizeReceivedString, sizeTotalString];
    
    if(download.status == PutIODownloadStatusDownloading && download.progressIsKnown){
        statusString = sizesString;
        if(download.bytesPerSecond > 0){
            NSString *speedString = unitStringFromBytes(download.bytesPerSecond);
            statusString = [statusString stringByAppendingFormat:@" (%@/s)", speedString];
        }
        statusString = [statusString stringByAppendingString:@" - "];
        if(download.estimatedRemainingTimeIsKnown){
            statusString = [statusString stringByAppendingFormat:@"%@remaining", unitStringFromSeconds(download.estimatedRemainingTime)];
        }else{
            statusString = [statusString stringByAppendingString:NSLocalizedString(@"Estimating remaining time", nil)];
        }
    }
    else if(download.status == PutIODownloadStatusPaused){
        statusString = [NSString stringWithFormat:@"%@ - %@", sizesString, download.localizedStatus];
    }
    else if(download.status == PutIODownloadStatusFinished){
        statusString = [NSString stringWithFormat:@"%@ - %@", sizeTotalString, download.localizedStatus];
    }
    else if(download.status == PutIODownloadStatusFailed){
        if(download.downloadError)
            statusString = [NSString stringWithFormat:@"%@: %@", download.localizedStatus, download.downloadError.localizedDescription];
    }
    statusLabel.stringValue = statusString;
}

-(IBAction)pauseOrResumeDownload:(id)sender
{
    if(_download.status == PutIODownloadStatusDownloading)
        [_download pauseDownload];
    else if(_download.status == PutIODownloadStatusPaused || _download.status == PutIODownloadStatusFailed)
        [_download startDownload];
}

#pragma mark - Icon Loading

static NSMutableDictionary *iconCache;

+ (void)cacheIconImage:(NSImage*)image forURL:(NSURL*)iconURL
{
    if(!iconCache)
        iconCache = [[NSMutableDictionary alloc] init];
    iconCache[iconURL] = image;
}

+ (NSImage*)cachedIconImageForURL:(NSURL*)iconURL
{
    if(!iconCache)
        return nil;
    return iconCache[iconURL];
}

- (void)loadIcon
{
    [iconLoader cancel];
    iconLoader = nil;
    NSURL *iconURL = _download.putioFile.iconURL;
    NSImage *iconImage = [DownloadCellView cachedIconImageForURL:iconURL];
    if(iconImage){
        self.imageView.image = iconImage;
    }else{
        self.imageView.image = [NSImage imageNamed:@"iconPlaceholder.png"];
        iconImageData = [[NSMutableData alloc] init];
        NSURLRequest *request = [NSURLRequest requestWithURL:_download.putioFile.iconURL
                                                 cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                             timeoutInterval:60.0f];
        iconLoader = [NSURLConnection connectionWithRequest:request delegate:self];        
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [iconImageData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSURL *iconURL = _download.putioFile.iconURL;
    NSImage *iconImage = [[NSImage alloc] initWithData:iconImageData];
    iconImageData = nil;
    [DownloadCellView cacheIconImage:iconImage forURL:iconURL];
    self.imageView.image = iconImage;
    iconLoader = nil;
}

@end
