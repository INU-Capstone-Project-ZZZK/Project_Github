#include <vector>
#include <algorithm>
#include <iostream>

using namespace std;

vector<double> upslopes(const vector<double>& ppg) {
    int th = 6;                 // 임계값 초기화
    vector<double> pks;       // 초기화
    vector<double> pos_peak;  // 초기화
    int pos_peak_b = 0;         // 초기화
    int n_pos_peak = 0;         // 초기화
    int n_up = 0;               // 초기화
    int n_up_pre = 0;           // 초기화
    for (size_t i = 1; i < ppg.size(); ++i) {
        if (ppg[i] > ppg[i - 1]) {
            n_up++;
        } 
        else {
            if (n_up >= th) {
                pos_peak.push_back(i);
                pos_peak_b = 1;
                n_pos_peak++;
                n_up_pre = n_up; 
            } 
            else {
                if (pos_peak_b == 1) {
                    if (ppg[i - 1] > ppg[pos_peak[n_pos_peak-1]]) {
                        pos_peak[n_pos_peak-1] = i - 1;
                    } 
                    else {
                        pks.push_back(pos_peak[n_pos_peak-1]);
                    }
                    th = static_cast<int>(0.6 * n_up_pre);
                    pos_peak_b = 0;
                }
            }
            n_up = 0;
        }
    }
    return pks;
}

// peak beat의 고유한 값만 유지
// vector<double> tidy_beats(vector<double> beats){

//     vector<double> result ;
//     result.reserve(beats.size());
//     result.insert(result.end(),beats.begin(),beats.end());

//     sort(result.begin(), result.end());
//     result.erase(unique(result.begin(),result.end(),result.end()));

//     return result;
// }

vector<double> pulse_onsets_from_peaks(const vector<double>& sig, const vector<double>& peaks) {
    // 펄스 온셋 식별
    vector<double> onsets(peaks.size()-1);

    for (size_t wave_no = 0; wave_no < peaks.size() - 1; ++wave_no) {
        int min_index = 0;
        double min_value = numeric_limits<double>::max();
        
        // 신호에서 최소값 찾기
        for (int i = peaks[wave_no]; i < peaks[wave_no + 1]; ++i) {
            if (sig[i] < min_value) {
                min_value = sig[i];
                min_index = i;
            }
        }
        
        // 펄스 온셋 설정
        onsets[wave_no] = min_index+1;
    }

    return onsets;
}

int main() {
    // 메인 함수에서는 데이터를 읽고 처리하는 부분을 구현합니다.

    // 입력 데이터 불러오기 
    // sig로 

    vector<double> sig = {0.002108
,0.000777
,-0.000236
,-0.00081
,-0.000986
,-0.00093
,-0.00085
,-0.000906
,-0.001152
,-0.001538
,-0.001981
,-0.002424
,-0.002888
,-0.003457
,-0.004207
,-0.005113
,-0.005997
,-0.00655
,-0.006437
,-0.005437
,-0.003563
,-0.001083
,0.001556
,0.003885
,0.00558
,0.006553
,0.00695
,0.00705
,0.007118
,0.007295
,0.007553
,0.007737
,0.007656
,0.007187
,0.006331
,0.005218
,0.004053
,0.00304
,0.002312
,0.001889
,0.001689
,0.001554
,0.001335
,0.000951
,0.000419
,-0.000166
,-0.000692
,-0.001099
,-0.001426
,-0.001802
,-0.002364
,-0.003161
,-0.004067
,-0.004791
,-0.00496
,-0.004278
,-0.002659
,-0.000295
,0.002399
,0.004937
,0.006934
,0.008231
,0.008918
,0.00925
,0.009502
,0.009849
,0.010296
,0.010715
,0.010921
,0.010778
,0.010257
,0.009456
,0.00854
,0.007689
,0.007034
,0.006623
,0.006415
,0.006316
,0.006224
,0.006072
,0.005851
,0.005602
,0.005377
,0.005197
,0.005016
,0.004733
,0.004246
,0.00353
,0.002692
,0.001974
,0.001682
,0.002073
,0.003235
,0.005035
,0.00715
,0.009183
,0.0108
,0.011848
,0.012374
,0.012573
,0.012674
,0.012836
,0.013088
,0.013324
,0.013387
,0.013144
,0.012553
,0.011678
,0.010663
,0.009678
,0.008852
,0.008237
};

    // peak 디텍션
    vector<double> peaks = upslopes(sig);

    // 출력 
    // 남아있는 peak들만 솎아내기
   // peaks = tidy_beats(peaks);
    vector<double> onsets = pulse_onsets_from_peaks(sig, peaks);

    for(int i = 0; i<peaks.size(); i++) cout <<peaks[i] <<' ';
    cout <<"\n";
    for(int i = 0; i<onsets.size(); i++) cout <<onsets[i] <<' ';

    return 0;
}
