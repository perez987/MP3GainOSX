//
//  M3GLanguageSelectorController.m
//  MP3Gain Express
//

#import "M3GLanguageSelectorController.h"

// Layout constants — window height is derived from these so changes stay consistent
static const CGFloat     kRowHeight     = 36.0;  // height of each language row
static const CGFloat     kTableWidth    = 222.0; // scroll view / table width
static const CGFloat     kScrollViewX   = 39.0;  // scroll view left inset
static const CGFloat     kScrollViewY   = 68.0;  // scroll view bottom edge (above buttons)
static const CGFloat     kTopPadding    = 42.0;  // space above scroll view (below title bar)
static const CGFloat     kWindowWidth   = 300.0;
static const NSInteger   kLanguageCount = 7;     // must match the _languages array size

@interface M3GLanguageSelectorController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *languages;
@property (nonatomic, copy) NSString *initialLanguageCode;

@end

@implementation M3GLanguageSelectorController

+ (instancetype)sharedController {
    static M3GLanguageSelectorController *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[M3GLanguageSelectorController alloc] init];
    });
    return instance;
}

- (instancetype)init {
    // Panel height = rows below title bar: top padding + table + scroll-view Y offset
    CGFloat windowHeight = kTopPadding + kLanguageCount * kRowHeight + kScrollViewY;
    NSPanel *panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, kWindowWidth, windowHeight)
                                                styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    self = [super initWithWindow:panel];
    if (self) {
        _languages = @[
            @{@"code": @"de", @"name": @"Deutsch", @"flag": @"🇩🇪"},
            @{@"code": @"en", @"name": @"English", @"flag": @"🇬🇧"},
            @{@"code": @"es", @"name": @"Español", @"flag": @"🇪🇸"},
            @{@"code": @"fr", @"name": @"Français", @"flag": @"🇫🇷"},
            @{@"code": @"it", @"name": @"Italiano", @"flag": @"🇮🇹"},
            @{@"code": @"cs", @"name": @"Česko", @"flag": @"🇨🇿"},
            @{@"code": @"el", @"name": @"ελληνική", @"flag": @"🇬🇷"}
        ];
        [self buildUI];
    }
    return self;
}

- (void)buildUI {
    NSView *contentView = self.window.contentView;

    // Scroll view height = one row per language so all entries are visible without scrolling
    CGFloat tableHeight = _languages.count * kRowHeight + 6;
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(kScrollViewX, kScrollViewY, kTableWidth, tableHeight)];
    scrollView.hasVerticalScroller = YES;
    scrollView.borderType = NSBezelBorder;
    scrollView.autohidesScrollers = YES;

    _tableView = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, kTableWidth, tableHeight)];
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"language"];
    column.width = 204;
    [_tableView addTableColumn:column];
    _tableView.headerView = nil;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = kRowHeight;
    _tableView.gridStyleMask = NSTableViewGridNone;
    _tableView.allowsEmptySelection = NO;

    scrollView.documentView = _tableView;
    [contentView addSubview:scrollView];

    // Cancel button
    NSButton *cancelButton = [NSButton buttonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                target:self
                                                action:@selector(cancelAction:)];
    cancelButton.frame = NSMakeRect(90, 20, 90, 28);
    cancelButton.bezelStyle = NSBezelStyleRounded;
    cancelButton.keyEquivalent = @"\033";
    [contentView addSubview:cancelButton];

    // Accept button
    NSButton *acceptButton = [NSButton buttonWithTitle:NSLocalizedString(@"Accept", @"Accept")
                                                target:self
                                                action:@selector(acceptAction:)];
    acceptButton.frame = NSMakeRect(192, 20, 90, 28);
    acceptButton.bezelStyle = NSBezelStyleRounded;
    acceptButton.keyEquivalent = @"\r";
    [contentView addSubview:acceptButton];
}

- (void)showForWindow:(NSWindow *)parentWindow {
    // Determine current language
    NSString *currentLang = [[[NSUserDefaults standardUserDefaults] stringArrayForKey:@"AppleLanguages"] firstObject];
    currentLang = [currentLang componentsSeparatedByString:@"-"].firstObject;
    if (!currentLang || currentLang.length == 0) {
        currentLang = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode] ?: @"en";
    }
    _initialLanguageCode = currentLang;

    [self.window setTitle:NSLocalizedString(@"Language selector title", @"Select Language")];
    [_tableView reloadData];
    [self selectLanguageCode:currentLang];

    [self.window center];
    [parentWindow beginSheet:self.window completionHandler:nil];
}

- (void)selectLanguageCode:(NSString *)code {
    NSUInteger idx = [_languages indexOfObjectPassingTest:^BOOL(NSDictionary *lang, NSUInteger i, BOOL *stop) {
        return [lang[@"code"] isEqualToString:code];
    }];
    if (idx != NSNotFound) {
        [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
        [_tableView scrollRowToVisible:(NSInteger)idx];
    }
}

- (NSString *)selectedLanguageCode {
    NSInteger row = _tableView.selectedRow;
    if (row >= 0 && row < (NSInteger)_languages.count) {
        return _languages[row][@"code"];
    }
    return @"en";
}

- (void)cancelAction:(id)sender {
    [NSApp endSheet:self.window];
    [self.window orderOut:self];
}

- (void)acceptAction:(id)sender {
    NSString *selectedCode = [self selectedLanguageCode];
    BOOL languageChanged = ![selectedCode isEqualToString:_initialLanguageCode];

    [NSApp endSheet:self.window];
    [self.window orderOut:self];

    if (languageChanged) {
        [[NSUserDefaults standardUserDefaults] setObject:@[selectedCode] forKey:@"AppleLanguages"];

        NSAlert *alert = [NSAlert new];
        alert.messageText = NSLocalizedString(@"Language changed alert title", @"Language Changed");
        alert.informativeText = NSLocalizedString(@"Language changed message", @"Please restart the application to apply the new language.");
        [alert addButtonWithTitle:NSLocalizedString(@"OK", @"OK")];
        [alert runModal];
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return (NSInteger)_languages.count;
}

- (NSTableCellView *)makeCellView {
    NSTableCellView *cellView = [[NSTableCellView alloc] init];
    cellView.identifier = @"LanguageCell";

    NSTextField *textField = [NSTextField labelWithString:@""];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.font = [NSFont systemFontOfSize:14];
    [cellView addSubview:textField];
    cellView.textField = textField;

    [NSLayoutConstraint activateConstraints:@[
        [textField.centerYAnchor constraintEqualToAnchor:cellView.centerYAnchor],
        [textField.leadingAnchor constraintEqualToAnchor:cellView.leadingAnchor constant:8],
        [textField.trailingAnchor constraintEqualToAnchor:cellView.trailingAnchor constant:-8]
    ]];
    return cellView;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"LanguageCell" owner:self];
    if (!cellView) {
        cellView = [self makeCellView];
    }
    NSDictionary *lang = _languages[row];
    cellView.textField.stringValue = [NSString stringWithFormat:@"%@  %@", lang[@"flag"], lang[@"name"]];
    return cellView;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return kRowHeight;
}

@end
